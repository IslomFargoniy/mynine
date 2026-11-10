<?php

use App\Jobs\ImportMockModuleJob;
use App\Models\Attempt;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\Section;
use App\Models\Test as ExamTest;
use App\Models\TestImport;
use App\Models\TestType;
use App\Services\Desktop\ExamPayloadBuilder;
use App\Services\ExamService;
use App\Services\Import\DocumentTextExtractor;
use App\Services\Import\MockImportNormalizer;
use App\Services\Import\MockTestImporter;
use App\Services\Import\MockTestPdfParser;
use App\Services\MockBankService;
use App\Services\OpenAIService;
use Barryvdh\DomPDF\Facade\Pdf;
use GuzzleHttp\Psr7\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use OpenAI\Exceptions\RateLimitException;

/*
|--------------------------------------------------------------------------
| Fixtures
|--------------------------------------------------------------------------
*/

function seedImportQuestionTypes(): void
{
    foreach ([
        'multiple_choice' => 'radio', 'multiple_response' => 'checkbox', 'true_false' => 'radio', 'yes_no' => 'radio',
        'fill_blank' => 'text', 'matching' => 'select', 'essay' => 'textarea', 'complete_section' => 'text', 'drag_and_drop' => 'text',
    ] as $type => $input) {
        makeQuestionType($type, $input);
    }
}

/**
 * Empty folderless Mock Bank test with Listening, Reading and Writing modules.
 *
 * @return array{test: ExamTest, listening: TestType, reading: TestType, writing: TestType}
 */
function makeBankTest(string $name = 'Mock 7'): array
{
    $test = ExamTest::create(['folder_id' => null, 'name' => $name, 'purpose' => 'mock', 'open' => 0]);
    $modules = [];
    foreach (['Listening' => 30, 'Reading' => 60, 'Writing' => 60] as $type => $minute) {
        $modules[strtolower($type)] = TestType::create(['test_id' => $test->id, 'type_id' => makeType($type, $minute)->id]);
    }

    return ['test' => $test] + $modules;
}

/**
 * AI response shaped like the real "Mock Listening Test 7" paper + its answer key (shortened:
 * 12 questions over two parts).
 *
 * @return array<string, mixed>
 */
function listeningAiResponse(): array
{
    return [
        'parts' => [
            [
                'name' => 'Part 1',
                'passage_html' => '',
                'sections' => [
                    [
                        'question_type' => 'complete_section',
                        'instructions_html' => '<p><strong>Questions 1-3</strong></p><p>Complete the notes below. Write ONE WORD AND/OR A NUMBER for each answer.</p>',
                        'content_html' => '<h4>Rental Property Application Form</h4><p>Phone number: [[1]] (mobile)</p><p>Email address: Susansmith@ [[2]]</p><p onclick="x()">Colour: [[3]]</p>',
                        'questions' => [['numbers' => [1], 'text' => ''], ['numbers' => [2], 'text' => ''], ['numbers' => [3], 'text' => '']],
                    ],
                    [
                        'question_type' => 'multiple_choice',
                        'instructions_html' => '<p><strong>Questions 4-5</strong></p><p>Choose the correct letter, A, B or C.</p>',
                        'questions' => [
                            ['numbers' => [4], 'text' => 'When does the riding in the park open?', 'options' => ['A 9.00 a.m.', 'B 9.30 a.m.', 'C 10.00 a.m.']],
                            ['numbers' => [5], 'text' => 'How much does a ticket cost?', 'options' => ['£78', '£95', '£113']],
                        ],
                    ],
                ],
            ],
            [
                'name' => 'Part 2',
                'passage_html' => '<p>ignored for listening</p>',
                'sections' => [
                    [
                        'question_type' => 'matching',
                        'instructions_html' => '<p>Choose FOUR answers from the box.</p><p>A doesn\'t have a long wait</p><p>G has a surprising ending</p>',
                        'from_option' => 'A',
                        'to_option' => 'G',
                        'questions' => [['numbers' => [6], 'text' => 'Cowboy Show'], ['numbers' => [7], 'text' => 'Magic Show']],
                    ],
                    [
                        'question_type' => 'multiple_response',
                        'instructions_html' => '<p>Questions 8 and 9. Choose TWO letters, A-E.</p>',
                        'questions' => [['numbers' => [8, 9], 'text' => 'Which TWO treatment techniques did the runner find useful?', 'options' => ['massage', 'ultrasound', 'rest', 'balancing exercises', 'ice']]],
                    ],
                    [
                        'question_type' => 'multiple_response',
                        'instructions_html' => '<p>Questions 10 and 11. Choose TWO letters, A-E.</p>',
                        'questions' => [['numbers' => [10, 11], 'text' => 'Which TWO sports were most effective?', 'options' => ['swimming', 'weight-training', 'running on grass', 'cycling', 'jumping']]],
                    ],
                    [
                        'question_type' => 'fill_blank',
                        'instructions_html' => '<p>Write NO MORE THAN TWO WORDS.</p>',
                        'questions' => [['numbers' => [12], 'text' => 'The birds keep their [[12]] even in fog.']],
                    ],
                ],
            ],
        ],
        'answers' => [
            '1' => '614381997', '2' => 'post.com', '3' => 'gray/grey', '4' => 'C', '5' => 'B',
            '6' => 'a', '7' => 'G', '8' => 'A', '9' => 'C', '10' => 'B', '11' => 'D',
            '12' => '(migration) direction',
        ],
    ];
}

/**
 * One Reading passage with TRUE/FALSE/NOT GIVEN, YES/NO/NOT GIVEN and a drag-and-drop summary.
 *
 * @return array<string, mixed>
 */
function readingPassageAiResponse(int $passage, int $first): array
{
    return [
        'parts' => [[
            'name' => "Passage {$passage}",
            'passage_html' => '<h3>The Clipper Races</h3><p style="color:red">'.str_repeat('During the seventeenth and eighteenth centuries the company had the monopoly on trade. ', 5).'</p><script>alert(1)</script>',
            'sections' => [
                [
                    'question_type' => 'true_false',
                    'instructions_html' => '<p>Do the following statements agree with the information given in Reading Passage '.$passage.'?</p>',
                    'questions' => [
                        ['numbers' => [$first], 'text' => 'The company had a monopoly.'],
                        ['numbers' => [$first + 1], 'text' => 'Cargo size mattered most.'],
                        ['numbers' => [$first + 2], 'text' => 'Voyages were dangerous.'],
                    ],
                ],
                [
                    'question_type' => 'yes_no',
                    'instructions_html' => '<p>Do the following statements agree with the claims of the writer?</p>',
                    'questions' => [['numbers' => [$first + 3], 'text' => 'Accidents help business.']],
                ],
                [
                    'question_type' => 'drag_and_drop',
                    'instructions_html' => '<p>Complete the summary using the list of words, A-D, below.</p>',
                    'content_html' => '<p>Clippers carried more [[{FIRST5}]] and faced fewer [[{FIRST6}]].</p>',
                    'options' => ['sails', 'storms', 'ports', 'tugs'],
                ],
            ],
        ]],
        'answers' => [
            (string) $first => 'TRUE', (string) ($first + 1) => 'FALSE', (string) ($first + 2) => 'NOTGIVEN',
            (string) ($first + 3) => 'NOT GIVEN', (string) ($first + 4) => 'A', (string) ($first + 5) => 'storms',
        ],
    ];
}

function readingAi(int $passage, int $first): array
{
    $response = readingPassageAiResponse($passage, $first);
    $section = &$response['parts'][0]['sections'][2];
    $section['content_html'] = str_replace(['{FIRST5}', '{FIRST6}'], [(string) ($first + 4), (string) ($first + 5)], $section['content_html']);

    return $response;
}

beforeEach(function () {
    seedImportQuestionTypes();
    $this->admin = makeUser('Admin');
});

/*
|--------------------------------------------------------------------------
| Text extraction
|--------------------------------------------------------------------------
*/

test('the extractor reads PDF text page by page and keeps page breaks', function () {
    $html = '<p>INTERNATIONAL ENGLISH LANGUAGE TESTING SYSTEM</p><p>LISTENING PART 1 Questions 1-10</p>'
        .'<div style="page-break-after: always"></div>'
        .'<p>PART 2 Questions 11-20</p><p>11 When does the riding in the park open?</p><p>A 9.00 a.m.</p><p>B 9.30 a.m.</p>';
    $path = tempnam(sys_get_temp_dir(), 'pdf').'.pdf';
    file_put_contents($path, Pdf::loadHTML($html)->output());

    $text = app(DocumentTextExtractor::class)->extract($path);
    @unlink($path);

    expect($text)->toStartWith('--- Page 1 ---')
        ->toContain('--- Page 2 ---')
        ->toContain('LISTENING PART 1 Questions 1-10')
        ->toContain('11 When does the riding in the park open?')
        ->toContain('A 9.00 a.m.');
    expect(strpos($text, 'Questions 1-10'))->toBeLessThan(strpos($text, '--- Page 2 ---'));
});

test('the extractor reads .docx paragraphs and .txt files', function () {
    $path = tempnam(sys_get_temp_dir(), 'docx').'.docx';
    $zip = new ZipArchive;
    $zip->open($path, ZipArchive::CREATE);
    $zip->addFromString('word/document.xml', '<w:document><w:body>'
        .'<w:p><w:r><w:t>READING PASSAGE 1</w:t></w:r></w:p>'
        .'<w:p><w:r><w:t>1</w:t><w:tab/><w:t>The company had a monopoly &amp; ships.</w:t></w:r></w:p>'
        .'<w:p><w:r><w:br w:type="page"/><w:t>READING PASSAGE 2</w:t></w:r></w:p>'
        .'</w:body></w:document>');
    $zip->close();

    $text = app(DocumentTextExtractor::class)->extract($path);
    @unlink($path);

    expect($text)->toContain("READING PASSAGE 1\n1 The company had a monopoly & ships.")
        ->toContain('--- Page 2 ---')
        ->toContain('READING PASSAGE 2');

    $txt = tempnam(sys_get_temp_dir(), 'txt');
    file_put_contents($txt, "1FALSE\r\n2TRUE\t \r\n\r\n\r\n\r\n15(migration)direction ﬀ");
    expect(app(DocumentTextExtractor::class)->extract($txt, 'txt'))->toBe("1FALSE\n2TRUE\n\n15(migration)direction ff");
    @unlink($txt);
});

test('a long reading paper is split into one AI call per passage', function () {
    $text = "Cover page\n".implode("\n", array_map(
        fn ($n) => "READING PASSAGE {$n}\n".str_repeat("Passage {$n} text line.\n", 300),
        [1, 2, 3],
    ));

    $chunks = app(MockTestPdfParser::class)->chunks('Reading', $text);
    expect($chunks)->toHaveCount(3);
    expect(array_values($chunks)[1])->toStartWith('READING PASSAGE 2')->not->toContain('PASSAGE 3');
    expect(array_keys($chunks)[2])->toContain('Reading Passage 3 only');

    expect(app(MockTestPdfParser::class)->chunks('Listening', $text))->toHaveCount(1);
    expect(app(MockTestPdfParser::class)->chunks('Reading', 'READING PASSAGE 1 short'))->toHaveCount(1);
});

/*
|--------------------------------------------------------------------------
| Normalisation and database rows
|--------------------------------------------------------------------------
*/

test('listening AI JSON becomes rows with the answer key applied by question number', function () {
    ['listening' => $module] = makeBankTest();

    $result = app(MockImportNormalizer::class)->normalize('Listening', [listeningAiResponse()]);
    expect($result['questions'])->toBe(12)
        ->and($result['warnings'])->toContain('Found 12 questions; a full Listening paper has 40.')
        ->and($result['warnings'])->toContain('Found 2 parts; a full Listening paper has 4.');

    $counts = app(MockTestImporter::class)->import($module, $result['parts'], false);
    expect($counts)->toBe(['parts' => 2, 'questions' => 10]);

    $parts = Part::where('test_type_id', $module->id)->orderBy('id')->get();
    expect($parts->pluck('name')->all())->toBe(['Part 1', 'Part 2'])
        ->and($parts[1]->textarea)->toBeNull(); // Listening has no passage

    // complete_section: gaps written as {answer} in the section text, one ordered question per gap
    $notes = Section::where('part_id', $parts[0]->id)->orderBy('id')->first();
    expect($notes->question_type->type)->toBe('complete_section')
        ->and($notes->textarea)->toContain('Phone number: {614381997} (mobile)')
        ->and($notes->textarea)->toContain('{gray/grey}')
        ->and($notes->textarea)->not->toContain('onclick')
        ->and($notes->textarea)->toContain('<strong>Questions 1-3</strong>');
    expect($notes->questions->sortBy('order')->map(fn ($q) => [$q->order, $q->answer_text])->values()->all())
        ->toBe([[1, '614381997'], [2, 'post.com'], [3, 'gray/grey']]);

    // multiple choice: letters stripped from the option texts, the key letter marks the correct option
    $mc = Question::where('textarea', 'When does the riding in the park open?')->firstOrFail();
    expect($mc->options->pluck('textarea')->all())->toBe(['9.00 a.m.', '9.30 a.m.', '10.00 a.m.'])
        ->and($mc->options->where('is_correct', true)->pluck('textarea')->all())->toBe(['10.00 a.m.']);

    // matching: letter range on the section, letter answers on the questions
    $matching = Section::whereHas('question_type', fn ($q) => $q->where('type', 'matching'))->firstOrFail();
    expect([$matching->from_option, $matching->to_option])->toBe(['A', 'G'])
        ->and($matching->questions->pluck('answer_text', 'textarea')->all())->toBe(['Cowboy Show' => 'A', 'Magic Show' => 'G']);

    // multiple response "27&28 in either order A C": one question, two correct options, worth two numbers
    $mr = Question::where('textarea', 'like', 'Which TWO treatment%')->firstOrFail();
    expect($mr->options->where('is_correct', true)->pluck('textarea')->values()->all())->toBe(['massage', 'rest'])
        ->and($mr->is_correct_count)->toBe(2);
    $mr2 = Question::where('textarea', 'like', 'Which TWO sports%')->firstOrFail();
    expect($mr2->options->where('is_correct', true)->pluck('textarea')->values()->all())->toBe(['weight-training', 'cycling']);

    // fill_blank: plain text with one {} input; optional words expand into alternatives
    $fill = Question::where('textarea', 'like', 'The birds keep%')->firstOrFail();
    expect($fill->textarea)->toBe('The birds keep their {} even in fog.')
        ->and($fill->answer_text)->toBe('migration direction/direction');

    // Numbering in the exam rooms: part 2 starts after the 5 numbers of part 1.
    expect($parts[1]->fresh()->order)->toBe(5);

    // All answers present: the readiness check only misses the audio.
    expect(app(MockBankService::class)->moduleIssues($module->fresh()))->toBe(['no_audio']);
});

test('reading passages get passage HTML, TRUE/FALSE/NOT GIVEN, YES/NO and drag-and-drop answers', function () {
    ['reading' => $module] = makeBankTest();

    $result = app(MockImportNormalizer::class)->normalize('Reading', [readingAi(1, 1), readingAi(2, 7)]);
    app(MockTestImporter::class)->import($module, $result['parts'], false);

    $parts = Part::where('test_type_id', $module->id)->orderBy('id')->get();
    expect($parts->pluck('name')->all())->toBe(['Passage 1', 'Passage 2'])
        ->and($parts[0]->textarea)->toStartWith('<h3>The Clipper Races</h3><p>During')
        ->and($parts[0]->textarea)->not->toContain('script')
        ->and($parts[0]->textarea)->not->toContain('style');

    $tf = Question::where('textarea', 'like', 'The company had%')->orderBy('id')->get();
    expect($tf)->toHaveCount(2)
        ->and($tf[0]->options->pluck('textarea')->all())->toBe(['True', 'False', 'Not Given'])
        ->and($tf[0]->options->firstWhere('is_correct', true)->textarea)->toBe('True');
    expect(Question::where('textarea', 'Cargo size mattered most.')->first()->options->firstWhere('is_correct', true)->textarea)->toBe('False')
        ->and(Question::where('textarea', 'Voyages were dangerous.')->first()->options->firstWhere('is_correct', true)->textarea)->toBe('Not Given');

    $yn = Question::where('textarea', 'Accidents help business.')->first();
    expect($yn->options->pluck('textarea')->all())->toBe(['Yes', 'No', 'Not Given'])
        ->and($yn->options->firstWhere('is_correct', true)->textarea)->toBe('Not Given');

    // drag_and_drop: letter answers resolve to box words, the unused words become distractors
    $dnd = Section::where('part_id', $parts[0]->id)->whereHas('question_type', fn ($q) => $q->where('type', 'drag_and_drop'))->firstOrFail();
    expect($dnd->textarea)->toContain('carried more {sails} and faced fewer {storms}')
        ->and($dnd->questions->sortBy('order')->pluck('answer_text')->values()->all())->toBe(['sails', 'storms'])
        ->and($dnd->options->pluck('textarea')->all())->toBe(['ports', 'tugs']);

    expect($result['warnings'])->toContain('Found 12 questions; a full Reading paper has 40.');
});

test('missing answers and broken numbering are reported as warnings, not failures', function () {
    ['listening' => $module] = makeBankTest();

    $response = listeningAiResponse();
    $response['answers'] = ['1' => '614381997'];
    unset($response['parts'][1]['sections'][3]); // drop question 12
    $response['parts'][0]['sections'][1]['questions'][1]['numbers'] = [4]; // duplicate 4, no 5
    $response['parts'][0]['sections'][0]['question_type'] = 'unknown_type';

    $result = app(MockImportNormalizer::class)->normalize('Listening', [$response]);

    expect($result['warnings'])->toContain('Duplicate question numbers: 4.')
        ->and($result['warnings'])->toContain('Question numbers missing: 5.')
        ->and(collect($result['warnings'])->first(fn ($w) => str_starts_with($w, 'Answers missing for questions')))->toBe('Answers missing for questions 2-4, 6-11 — add them in the module editor.')
        ->and(collect($result['warnings'])->contains(fn ($w) => str_contains($w, 'unknown question type "unknown_type" was imported as complete_section')))->toBeTrue();

    app(MockTestImporter::class)->import($module, $result['parts'], false);

    // Unanswered gaps stay as empty gaps and the readiness check lists them.
    expect(Section::whereHas('question_type', fn ($q) => $q->where('type', 'complete_section'))->first()->textarea)->toContain('Susansmith@ {}');
    expect(app(MockBankService::class)->moduleIssues($module->fresh()))->toContain('missing_answer_keys:8');
});

test('a response without parts is rejected', function () {
    app(MockImportNormalizer::class)->normalize('Listening', [['answers' => []]]);
})->throws(RuntimeException::class, 'no "parts"');

test('import refuses a module that already has parts unless replace is set', function () {
    ['listening' => $module] = makeBankTest();
    $old = Part::create(['test_type_id' => $module->id, 'name' => 'Old part']);
    $oldSection = makeSection($old, 'fill_blank');
    $parts = app(MockImportNormalizer::class)->normalize('Listening', [listeningAiResponse()])['parts'];

    expect(fn () => app(MockTestImporter::class)->import($module, $parts, false))->toThrow(RuntimeException::class, 'already has parts');
    expect(Part::where('test_type_id', $module->id)->pluck('name')->all())->toBe(['Old part']);

    app(MockTestImporter::class)->import($module, $parts, true);
    expect(Part::where('test_type_id', $module->id)->pluck('name')->all())->toBe(['Part 1', 'Part 2'])
        ->and(Section::find($oldSection->id))->toBeNull();
});

/*
|--------------------------------------------------------------------------
| Upload + queued job
|--------------------------------------------------------------------------
*/

test('the upload stores the files, sets the listening audio and queues one job per module', function () {
    Storage::fake('local');
    Queue::fake();
    ['test' => $test] = makeBankTest();

    $this->actingAs($this->admin)->post(route('mock-bank.import', $test), [
        'listening_file' => UploadedFile::fake()->create('Mock Listening Test 7.pdf', 100, 'application/pdf'),
        'reading_file' => UploadedFile::fake()->create('Mock Test 7 Reading.pdf', 100, 'application/pdf'),
        'answers_file' => UploadedFile::fake()->create('Answers.pdf', 10, 'application/pdf'),
        'listening_audio' => UploadedFile::fake()->create('test7.mp3', 200, 'audio/mpeg'),
    ])->assertSessionHasNoErrors()->assertSessionHas('success');

    $import = TestImport::firstOrFail();
    expect($import->status)->toBe(TestImport::QUEUED)
        ->and($import->replace)->toBeFalse()
        ->and(array_keys($import->modules))->toBe(['Listening', 'Reading'])
        ->and($import->files)->toBe([
            'listening' => "imports/{$test->id}/{$import->id}/listening.pdf",
            'reading' => "imports/{$test->id}/{$import->id}/reading.pdf",
            'answers' => "imports/{$test->id}/{$import->id}/answers.pdf",
        ]);
    Storage::disk('local')->assertExists($import->files['answers']);
    expect($test->fresh()->audio_path)->toStartWith('media/audio/');

    Queue::assertPushed(ImportMockModuleJob::class, 2);
    Queue::assertPushed(ImportMockModuleJob::class, fn ($job) => $job->module === 'Reading' && $job->importId === $import->id);
});

test('the upload validates files, existing parts and running imports', function () {
    Storage::fake('local');
    Queue::fake();
    ['test' => $test, 'reading' => $reading] = makeBankTest();
    $pdf = fn () => UploadedFile::fake()->create('r.pdf', 10, 'application/pdf');

    // At least one module file; Writing is not imported.
    $this->actingAs($this->admin)->post(route('mock-bank.import', $test), ['answers_file' => $pdf()])->assertSessionHasErrors('listening_file');
    $this->actingAs($this->admin)->post(route('mock-bank.import', $test), ['reading_file' => UploadedFile::fake()->create('r.exe', 10)])->assertSessionHasErrors('reading_file');

    Part::create(['test_type_id' => $reading->id, 'name' => 'Existing']);
    $this->actingAs($this->admin)->post(route('mock-bank.import', $test), ['reading_file' => $pdf()])->assertSessionHasErrors('reading_file');
    expect(TestImport::count())->toBe(0);

    $this->actingAs($this->admin)->post(route('mock-bank.import', $test), ['reading_file' => $pdf(), 'replace' => 1])->assertSessionHasNoErrors();
    expect(TestImport::first()->replace)->toBeTrue();

    // A second import while the first is queued is refused.
    $this->actingAs($this->admin)->post(route('mock-bank.import', $test), ['reading_file' => $pdf(), 'replace' => 1])->assertSessionHasErrors('listening_file');

    // Practice tests are not in the Mock Bank.
    ['test' => $practice] = makeTestContent($this->admin);
    $this->actingAs($this->admin)->post(route('mock-bank.import', $practice), ['reading_file' => $pdf()])->assertNotFound();

    Queue::assertPushed(ImportMockModuleJob::class, 1);
});

test('reception and students cannot import', function () {
    Storage::fake('local');
    Queue::fake();
    ['test' => $test] = makeBankTest();

    foreach (['Reception', 'Student'] as $role) {
        $this->actingAs(makeUser($role))->post(route('mock-bank.import', $test), [
            'reading_file' => UploadedFile::fake()->create('r.pdf', 10, 'application/pdf'),
        ])->assertForbidden();
    }

    expect(TestImport::count())->toBe(0);
    Queue::assertNothingPushed();
});

test('the job moves queued -> running -> done, stores warnings and deletes the files', function () {
    Storage::fake('local');
    ['test' => $test, 'listening' => $listening, 'reading' => $reading] = makeBankTest();

    $import = TestImport::create([
        'test_id' => $test->id, 'status' => TestImport::QUEUED,
        'modules' => ['Listening' => ['status' => 'queued'], 'Reading' => ['status' => 'queued']],
    ]);
    $dir = ImportMockModuleJob::directory($test->id, $import->id);
    Storage::disk('local')->put("{$dir}/listening.txt", "LISTENING\nPART 1 Questions 1-10\n1 Phone number ....");
    Storage::disk('local')->put("{$dir}/reading.txt", "READING PASSAGE 1\nThe Clipper Races");
    Storage::disk('local')->put("{$dir}/answers.txt", "LISTENING\n1614381997\nREADING\n1FALSE");
    $import->forceFill(['files' => ['listening' => "{$dir}/listening.txt", 'reading' => "{$dir}/reading.txt", 'answers' => "{$dir}/answers.txt"]])->save();

    $this->mock(OpenAIService::class, function ($mock) {
        $mock->shouldReceive('parseMockModule')
            ->once()
            ->withArgs(fn ($module, $text, $key, $scope) => $module === 'Listening' && str_contains($text, 'PART 1 Questions 1-10') && str_contains($key, '1614381997') && $scope === 'the whole Listening paper')
            ->andReturn(listeningAiResponse());
        $mock->shouldReceive('parseMockModule')
            ->once()
            ->withArgs(fn ($module) => $module === 'Reading')
            ->andReturn(readingAi(1, 1));
    });

    app()->call([new ImportMockModuleJob($import->id, 'Listening'), 'handle']);

    $import->refresh();
    expect($import->status)->toBe(TestImport::RUNNING) // Reading is still queued
        ->and($import->modules['Listening']['status'])->toBe(TestImport::DONE)
        ->and($import->modules['Listening']['questions'])->toBe(10)
        ->and($import->modules['Listening']['warnings'])->toContain('Found 12 questions; a full Listening paper has 40.');
    Storage::disk('local')->assertExists("{$dir}/answers.txt");

    app()->call([new ImportMockModuleJob($import->id, 'Reading'), 'handle']);

    $import->refresh();
    expect($import->status)->toBe(TestImport::DONE)
        ->and($import->finished_at)->not->toBeNull()
        ->and(Part::where('test_type_id', $listening->id)->count())->toBe(2)
        ->and(Part::where('test_type_id', $reading->id)->count())->toBe(1);
    Storage::disk('local')->assertMissing($dir);

    // Running a finished module again is a no-op.
    app()->call([new ImportMockModuleJob($import->id, 'Reading'), 'handle']);
    expect(Part::where('test_type_id', $reading->id)->count())->toBe(1);
});

test('a failing module is marked failed with its message and keeps the files', function () {
    Storage::fake('local');
    ['test' => $test] = makeBankTest();
    $import = TestImport::create(['test_id' => $test->id, 'status' => TestImport::QUEUED, 'modules' => ['Listening' => ['status' => 'queued']]]);
    $dir = ImportMockModuleJob::directory($test->id, $import->id);
    Storage::disk('local')->put("{$dir}/listening.txt", 'LISTENING PART 1');
    $import->forceFill(['files' => ['listening' => "{$dir}/listening.txt"]])->save();

    $this->mock(OpenAIService::class, fn ($mock) => $mock->shouldReceive('parseMockModule')->andThrow(new RuntimeException('The AI did not return valid JSON.')));

    $job = new ImportMockModuleJob($import->id, 'Listening');
    try {
        app()->call([$job, 'handle']);
    } catch (RuntimeException $e) {
        $job->failed($e);
    }

    $import->refresh();
    expect($import->status)->toBe(TestImport::FAILED)
        ->and($import->modules['Listening']['status'])->toBe(TestImport::FAILED)
        ->and($import->modules['Listening']['message'])->toBe('The AI did not return valid JSON.');
    Storage::disk('local')->assertExists("{$dir}/listening.txt");
});

/*
|--------------------------------------------------------------------------
| Mock Bank page, exam payloads
|--------------------------------------------------------------------------
*/

test('the mock bank card links Edit content to the Listening module and shows the import status', function () {
    ['test' => $test, 'listening' => $listening] = makeBankTest();
    TestImport::create(['test_id' => $test->id, 'status' => TestImport::RUNNING, 'modules' => [
        'Listening' => ['status' => 'done', 'warnings' => ['Found 38 questions; a full Listening paper has 40.'], 'parts' => 4, 'questions' => 36],
        'Reading' => ['status' => 'running'],
    ]]);

    $this->actingAs($this->admin)->get(route('mock-bank.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->component('mock-bank/index')
            ->where('tests.0.edit_module_id', $listening->id)
            ->where('tests.0.folder', null)
            ->where('tests.0.import.status', 'running')
            ->where('tests.0.import.modules.0.type', 'Listening')
            ->where('tests.0.import.modules.0.warnings.0', 'Found 38 questions; a full Listening paper has 40.')
            ->where('tests.0.import.modules.1.status', 'running'));
});

test('gap answers are masked for candidates and matching letters reach the desktop app as strings', function () {
    ['test' => $test, 'listening' => $module] = makeBankTest();
    $parts = app(MockImportNormalizer::class)->normalize('Listening', [listeningAiResponse()])['parts'];
    app(MockTestImporter::class)->import($module, $parts, false);

    $part = Part::where('test_type_id', $module->id)->orderBy('id')->first();
    app(ExamService::class)->hideAnswerKeys($part);
    $section = $part->sections->sortBy('id')->first();
    expect($section->textarea)->toContain('Phone number: {} (mobile)')->not->toContain('614381997');
    expect(json_encode($part->toArray()))->not->toContain('614381997');

    // Stored content is untouched.
    expect(Section::find($section->id)->textarea)->toContain('{614381997}');

    $attempt = Attempt::create(['name' => 'Candidate', 'test_id' => $test->id, 'started_at' => now(), 'finished_at' => now()->addHours(3)]);
    $payload = app(ExamPayloadBuilder::class)->prefetch($attempt, collect([$module->fresh()->load(['type', 'test'])]));

    $json = json_encode($payload['parts']);
    expect($json)->not->toContain('614381997')->not->toContain('gray/grey');
    $matching = collect($payload['parts'])->pluck('sections')->flatten(1)->firstWhere('question_type', 'matching');
    expect($matching['from_option'])->toBe('A')->and($matching['to_option'])->toBe('G');
    expect(collect($payload['parts'])->pluck('sections')->flatten(1)->firstWhere('question_type', 'complete_section')['html'])->toContain('Phone number: {} (mobile)');
});

test('a 429 from OpenAI is explained as a billing / rate limit problem', function () {
    $e = new RateLimitException(new Response(429));

    expect(ImportMockModuleJob::describe($e))->toContain('credit balance is exhausted')
        ->and(ImportMockModuleJob::describe(new RuntimeException('boom')))->toBe('boom');
});

test('an OpenAI rate limit puts the module back in the queue instead of failing', function () {
    Storage::fake('local');
    ['test' => $test] = makeBankTest();
    $import = TestImport::create(['test_id' => $test->id, 'status' => TestImport::QUEUED, 'modules' => ['Listening' => ['status' => 'queued']]]);
    $dir = ImportMockModuleJob::directory($test->id, $import->id);
    Storage::disk('local')->put("{$dir}/listening.txt", 'LISTENING PART 1');
    $import->forceFill(['files' => ['listening' => "{$dir}/listening.txt"]])->save();

    $this->mock(OpenAIService::class, fn ($mock) => $mock->shouldReceive('parseMockModule')->andThrow(new RateLimitException(new Response(429))));

    $job = (new ImportMockModuleJob($import->id, 'Listening'))->withFakeQueueInteractions();
    app()->call([$job, 'handle']);

    $job->assertReleased(90);
    expect($import->fresh()->modules['Listening']['status'])->toBe(TestImport::QUEUED)
        ->and($import->fresh()->modules['Listening']['message'])->toContain('retrying');
});
