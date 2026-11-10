<?php

namespace App\Services;

use OpenAI;
use OpenAI\Client;

class OpenAIService
{
    protected $client;

    public function __construct()
    {
        $this->client = OpenAI::client(config('services.openai.key'));
    }

    public function evaluateEssay(string $taskPrompt, string $questionText, string $essayText): string
    {
        $essayText = mb_substr($essayText, 0, 4000);
        $questionText = strip_tags($questionText);

        $promptText = <<<EOT
You are an IELTS examiner. Evaluate the following essay based on the four IELTS writing criteria:
1. Task Response
2. Coherence & Cohesion
3. Lexical Resource
4. Grammatical Range & Accuracy

Return a JSON object containing:
- "overall": The overall band score (0 to 9, e.g. 6.5).
- "scores": An object containing the individual criteria band scores:
  - "task_response"
  - "coherence_cohesion"
  - "lexical_resource"
  - "grammatical_range_accuracy"
- "feedback": Detailed feedback and recommendations (about 250 words) formatted in markdown.

Task: {$taskPrompt}
Question: {$questionText}
Essay: {$essayText}
EOT;

        $response = $this->client->chat()->create([
            'model' => 'gpt-4o-mini',
            'response_format' => ['type' => 'json_object'],
            'messages' => [
                ['role' => 'system', 'content' => 'You are an IELTS writing examiner. You must return your evaluation in the requested JSON structure.'],
                ['role' => 'user', 'content' => $promptText],
            ],
            'max_tokens' => 1200,
        ]);

        return $response->choices[0]->message->content ?? '{"overall": 0, "feedback": "No response from AI"}';
    }

    public function parseTestDocument(string $rawText): array
    {
        $rawText = mb_substr($rawText, 0, 15000);

        $promptText = <<<EOT
You are an expert IELTS test database parser. Your job is to parse the following raw text from an IELTS test (Reading, Listening, Writing, etc.) and extract all sections, question types, questions, and answers into a structured JSON schema.

Identify the question types from the text. The allowed question type values are:
- "multiple_choice" (One correct answer among A, B, C, D)
- "multiple_response" (Multiple correct answers among options)
- "true_false" (True / False / Not Given)
- "yes_no" (Yes / No / Not Given)
- "fill_blank" (Fill in the blanks/gaps in sentences or tables)
- "matching" (Matching headings, information, or features, e.g. matching letters A-G to questions)
- "essay" (Writing prompts/essays)
- "complete_section" (A passage with multiple inline gaps/drop-downs)
- "drag_and_drop" (Drag words into gap sentences)

For "matching" type:
- Identify the letter range options, e.g., if letters A to F are used, set "from_option" to "A" and "to_option" to "F".
- Set the correct letter (e.g., "C") in the "answer_text" field of the matching question.

For "drag_and_drop" type:
- If there are extra words (incorrect options/distractors) listed in the instructions or box, extract them into the section's "options" array as simple strings.

For "fill_blank":
- The correct text answer must be set in the question's "answer_text" field.

For Multiple Choice, Multiple Response, True/False, and Yes/No:
- Extract all option choices. Set "is_correct" to true for correct options, false otherwise.
- For True/False, extract options: "True", "False", "Not Given".
- For Yes/No, extract options: "Yes", "No", "Not Given".

Return a JSON object with a single key "sections" containing an array of sections:
{
  "sections": [
    {
      "textarea": "Instructions, passage excerpts, or title of this section. Can include clean HTML formatting.",
      "question_type": "multiple_choice",
      "from_option": "A",
      "to_option": "D",
      "options": ["Incorrect option 1", "Incorrect option 2"], // Only for drag_and_drop incorrect distractors
      "questions": [
        {
          "textarea": "Question text or number, e.g., '1. The author argues that...'",
          "answer_text": "C", // Used for matching, fill_blank, complete_section, drag_and_drop
          "options": [
            { "textarea": "First Choice", "is_correct": false },
            { "textarea": "Second Choice", "is_correct": true }
          ]
        }
      ]
    }
  ]
}

Raw Test Text:
{$rawText}
EOT;

        try {
            $response = $this->client->chat()->create([
                'model' => 'gpt-4o-mini',
                'response_format' => ['type' => 'json_object'],
                'messages' => [
                    ['role' => 'system', 'content' => 'You are a precise IELTS parser. You must parse the raw text and return your output as structured JSON matching the database schema.'],
                    ['role' => 'user', 'content' => $promptText],
                ],
                'max_tokens' => 4000,
            ]);

            $jsonString = $response->choices[0]->message->content ?? '{"sections": []}';

            return json_decode($jsonString, true) ?? ['sections' => []];
        } catch (\Exception $e) {
            return ['sections' => [], 'error' => $e->getMessage()];
        }
    }

    /**
     * Parse one Listening / Reading module (or one Reading passage) of a publisher PDF into parts,
     * sections and questions, plus the answer key by question number. The raw JSON is validated
     * and turned into database rows by App\Services\Import\MockImportNormalizer.
     *
     * @param  string  $module  "Listening" or "Reading"
     * @param  string  $scope  human description of the chunk, e.g. "the whole Listening paper" or "Reading Passage 2 only (questions 14-26)"
     * @return array<string, mixed>
     */
    public function parseMockModule(string $module, string $text, string $answerKeyText, string $scope): array
    {
        $keyBlock = trim($answerKeyText) !== ''
            ? $answerKeyText
            : '(No separate answer key was uploaded. If the question paper above contains an answer key, usually at the end, use it; otherwise return an empty "answers" object.)';

        $partWord = $module === 'Reading' ? 'passage' : 'part';
        $passageRule = $module === 'Reading'
            ? '- "passage_html": the COMPLETE reading passage text as clean HTML (<h3> for the title, <p> per paragraph; keep paragraph letters such as "A", "B" at the start of their paragraph as <strong>A</strong>). Re-join lines that the PDF broke in the middle of a sentence. Do not shorten, summarise or correct the passage. Do not include the questions.'
            : '- "passage_html": always "" for Listening.';

        $prompt = <<<EOT
You convert an IELTS {$module} question paper (text extracted from a PDF; line breaks and columns may be broken) into JSON for a test database.
Process {$scope}.

Return ONE JSON object:
{
  "parts": [
    {
      "name": "Part 1",
      "passage_html": "",
      "sections": [
        {
          "question_type": "multiple_choice",
          "instructions_html": "<p><strong>Questions 11-16</strong></p><p>Choose the correct letter, A, B or C.</p>",
          "content_html": "",
          "from_option": null,
          "to_option": null,
          "options": [],
          "questions": [
            { "numbers": [11], "text": "When does the riding in the park open?", "options": ["9.00 a.m.", "9.30 a.m.", "10.00 a.m."] }
          ]
        }
      ]
    }
  ],
  "answers": { "1": "614381997", "11": "C" }
}

Rules for "parts":
- One entry per {$partWord} in paper order{$this->partHint($module)}. "name": "Part N" for Listening, "Passage N" for Reading.
{$passageRule}
- Every question number of the paper must appear exactly once, in order. Never invent or skip questions.
- "question_type" is one of: multiple_choice, multiple_response, true_false, yes_no, fill_blank, matching, complete_section, drag_and_drop.
- "instructions_html": the task heading and instructions ("Questions 1-10", "Complete the notes below.", "Write ONE WORD AND/OR A NUMBER for each answer.", titles, and for matching the full list/box of options such as "A doesn't have a long wait", "B ..."). Clean HTML: <p>, <strong>, <ul><li>, <table> where the paper has a table.

How to model each task:
- Notes / form / table / flow-chart / summary / sentence completion where the gaps are inside a block of text: "complete_section". Put the whole block (title, labels, bullet points, table) in "content_html" as clean HTML and replace each gap with the marker [[N]] (N = question number), e.g. "<p>Phone number: [[1]] (mobile)</p>". Drop the dotted lines and the printed number of the gap. For forms printed in two columns, put each label next to its value again. "questions": [{"numbers":[N],"text":""}] for every gap, in order.
- Separate sentences each with one gap: "fill_blank"; "text" is the sentence with the gap written as [[N]] (plain text, no HTML).
- Choose ONE letter: "multiple_choice"; "text" = the question stem; "options" = the option texts WITHOUT their letters, in order A, B, C, D.
- Choose TWO (or THREE) letters: "multiple_response"; ONE question whose "numbers" lists all its numbers (e.g. [27, 28]); "options" = all option texts without letters.
- TRUE / FALSE / NOT GIVEN: "true_false"; YES / NO / NOT GIVEN: "yes_no"; one question per statement, "text" = the statement, "options": [].
- Matching (information to paragraphs, headings, features, people, sentence endings, "choose answers from the box and write the letter"): "matching"; "from_option"/"to_option" = first and last option letter (e.g. "A" and "G"; roman numerals "i"/"x" for heading lists); the option list goes into "instructions_html"; one question per numbered item, "text" = the item (e.g. "Cowboy Show").
- Summary completion with a word box of letters/words: "drag_and_drop"; "content_html" with [[N]] markers like complete_section; "options" = the words of the box (without letters, in box order).
- Question "text" is plain text without the question number.
- Ignore cover pages, candidate instructions, page numbers, copyright lines and "Example" rows that are already answered.

Rules for "answers" (take them ONLY from the ANSWER KEY below, never guess or solve the questions yourself):
- Object keyed by question number (string) for every number you find in the key for THIS {$module} section (the key may contain both Listening and Reading; use only the {$module} part{$this->scopeKeyHint($scope)}).
- The key text may have lost its spaces: restore normal spacing from context ("visualmemory" -> "visual memory", "NOTGIVEN" -> "NOT GIVEN"). In lines like "1614381997" the leading number is the question number (question 1, answer "614381997").
- Keep alternatives separated by "/" ("gray/grey") and optional words in round brackets ("(migration) direction").
- Letters stay single letters ("C"); TRUE/FALSE/NOT GIVEN and YES/NO/NOT GIVEN as written.
- "27&28 in either order A C" means "27": "A", "28": "C". Keys sometimes print the wrong numbers for the second either-order pair; assign each pair to the next multiple_response question in order.

QUESTION PAPER:
{$text}

ANSWER KEY:
{$keyBlock}
EOT;

        $response = $this->importClient()->chat()->create([
            'model' => (string) config('services.openai.import_model', 'gpt-4o'),
            'response_format' => ['type' => 'json_object'],
            'temperature' => 0,
            'max_tokens' => 16000,
            'messages' => [
                ['role' => 'system', 'content' => 'You are a meticulous IELTS test digitiser. You copy content faithfully and return only valid JSON in the requested schema.'],
                ['role' => 'user', 'content' => $prompt],
            ],
        ]);

        $choice = $response->choices[0] ?? null;
        if (($choice?->finishReason ?? null) === 'length') {
            throw new \RuntimeException('The AI response was cut off (too long). Split the PDF into smaller files.');
        }

        $decoded = json_decode((string) ($choice?->message->content ?? ''), true);
        if (! is_array($decoded)) {
            throw new \RuntimeException('The AI did not return valid JSON.');
        }

        return $decoded;
    }

    private function partHint(string $module): string
    {
        return $module === 'Listening' ? ' (a full Listening paper has 4 parts, 40 questions)' : ' (a full Reading paper has 3 passages, 40 questions)';
    }

    private function scopeKeyHint(string $scope): string
    {
        return str_contains($scope, 'only') ? ', and only the numbers of the questions you processed' : '';
    }

    /**
     * Client for the long import calls (a whole module can take a few minutes).
     */
    private function importClient(): Client
    {
        return OpenAI::factory()
            ->withApiKey((string) config('services.openai.key'))
            ->withHttpClient(new \GuzzleHttp\Client(['timeout' => (int) config('services.openai.import_timeout', 300)]))
            ->make();
    }
}
