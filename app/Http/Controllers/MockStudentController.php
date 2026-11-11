<?php

namespace App\Http\Controllers;

use App\Models\Mock;
use App\Models\MockStudent;
use App\Services\CandidateService;
use App\Services\ExamService;
use App\Support\Pdf;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class MockStudentController extends Controller
{
    /**
     * Add candidates to a mock (single or bulk). Phone is mandatory and stored as +998XXXXXXXXX.
     *
     * Accepts `candidates` ([{name, phone}]) or `text` (one "Name ; phone" line per candidate, see
     * CandidateService::parseLine). A row whose phone is empty but whose name holds one ("ali : 911157709")
     * is split the same way. Every invalid line gets its own error; nothing is saved then.
     */
    public function store(Request $request, CandidateService $candidates)
    {
        $request->validate([
            'mock_id' => 'required|exists:mocks,id',
            'text' => 'required_without:candidates|nullable|string|max:50000',
            'candidates' => 'required_without:text|array|min:1|max:500',
            'candidates.*.name' => 'nullable|string|max:255',
            'candidates.*.phone' => 'nullable|string|max:32',
        ]);

        $mock = Mock::findOrFail($request->mock_id);
        $this->authorize('manageStudents', $mock);

        $input = $request->filled('candidates')
            ? array_values($request->input('candidates'))
            : array_values(array_map(
                fn ($line) => CandidateService::parseLine($line),
                array_filter(preg_split('/\r\n|\r|\n/', (string) $request->input('text')), fn ($line) => trim($line) !== ''),
            ));

        if ($input === [] || count($input) > 500) {
            throw ValidationException::withMessages(['candidates' => __('candidates_count_invalid')]);
        }

        $rows = [];
        $errors = [];
        foreach ($input as $i => $candidate) {
            $name = (string) ($candidate['name'] ?? '');
            $rawPhone = trim((string) ($candidate['phone'] ?? ''));
            if ($rawPhone === '') {
                ['name' => $name, 'phone' => $rawPhone] = CandidateService::parseLine($name);
                $rawPhone = trim((string) $rawPhone);
            }
            $name = CandidateService::cleanName($name);
            $phone = CandidateService::normalizePhone($rawPhone);
            $line = $i + 1;

            if ($name === '') {
                $errors["candidates.{$i}.name"] = __('candidate_line_name_missing', ['line' => $line]);
            } elseif ($phone === null) {
                $errors["candidates.{$i}.phone"] = $rawPhone === ''
                    ? __('candidate_line_phone_missing', ['line' => $line, 'name' => $name])
                    : __('candidate_line_phone_invalid', ['line' => $line, 'name' => $name, 'phone' => $rawPhone]);
            } else {
                $rows[] = ['name' => mb_substr($name, 0, 255), 'phone' => $phone];
            }
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }

        $codes = MockStudent::generateBulkCodes(count($rows));
        $now = now();

        MockStudent::insert(array_map(fn ($row, $code) => [
            'mock_id' => $mock->id,
            'name' => $row['name'],
            'code' => $code,
            'phone' => $row['phone'],
            'attended' => false,
            'created_at' => $now,
            'updated_at' => $now,
        ], $rows, $codes));

        $repeats = collect($rows)
            ->filter(fn ($row) => $candidates->repeatModules($mock, $row['phone']) !== [])
            ->pluck('name');

        $response = back()->with('success', __('candidates_added', ['count' => count($rows)]));

        return $repeats->isEmpty()
            ? $response
            : $response->with('warning', __('candidates_repeat_warning', ['names' => $repeats->implode(', ')]));
    }

    /**
     * Repeat-candidate check before adding: which of the mock's modules each phone already sat.
     */
    public function checkRepeats(Request $request, CandidateService $candidates): JsonResponse
    {
        $request->validate([
            'mock_id' => 'required|exists:mocks,id',
            'phones' => 'required|array|max:500',
            'phones.*' => 'nullable|string|max:32',
        ]);

        $mock = Mock::findOrFail($request->mock_id);
        $this->authorize('manageStudents', $mock);

        $result = [];
        foreach ($request->input('phones') as $raw) {
            $phone = CandidateService::normalizePhone($raw);
            $result[] = [
                'input' => $raw,
                'phone' => $phone,
                'valid' => $phone !== null,
                'repeats' => $phone ? $candidates->repeatModules($mock, $phone) : [],
            ];
        }

        return response()->json(['data' => $result]);
    }

    /**
     * Printable candidate code cards (A4, 8 per page). ?ids=1,2,3 limits the selection.
     */
    public function codeCards(Request $request, Mock $mock)
    {
        $this->authorize('manageStudents', $mock);

        $ids = array_filter(array_map('intval', explode(',', (string) $request->query('ids', ''))));

        $students = MockStudent::withoutEagerLoads()
            ->where('mock_id', $mock->id)
            ->when($ids !== [], fn ($q) => $q->whereIn('id', $ids))
            ->orderBy('name')
            ->get();

        abort_if($students->isEmpty(), 404, __('candidates_not_found'));

        return Pdf::render('pdf.code-cards', compact('mock', 'students'), 'Codes_'.$mock->id);
    }

    /**
     * 80 mm receipt tickets for the Xprinter (browser print, one ticket per page so the driver cuts after each).
     * ?ids=1,2,3 limits the selection; ids of other mocks are ignored.
     */
    public function codeTickets(Request $request, Mock $mock)
    {
        $this->authorize('manageStudents', $mock);

        $ids = array_filter(array_map('intval', explode(',', (string) $request->query('ids', ''))));

        $students = MockStudent::withoutEagerLoads()
            ->where('mock_id', $mock->id)
            ->when($ids !== [], fn ($q) => $q->whereIn('id', $ids))
            ->orderBy('name')
            ->get(['id', 'name', 'code']);

        abort_if($students->isEmpty(), 404, __('candidates_not_found'));

        return response()->view('print.code-tickets', compact('mock', 'students'));
    }

    /**
     * Delete candidate (Admin)
     */
    public function destroy(MockStudent $mockStudent)
    {
        $this->authorize('deleteStudents', $mockStudent->mock);

        $mockStudent->delete();

        return back()->with('success', __('candidate_deleted'));
    }

    /**
     * Public endpoint for candidates entering mock exam via Candidate Code (MSXXXXXX)
     */
    public function enter(Request $request, ExamService $exam)
    {
        $request->validate([
            'code' => 'required|string',
        ]);

        $code = strtoupper(trim($request->code));

        $student = MockStudent::with(['mock.test'])->where('code', $code)->first();

        if (! $student) {
            if ($request->isMethod('get')) {
                return redirect('/?error='.urlencode(__('candidate_code_not_found', ['code' => $code])));
            }
            throw ValidationException::withMessages([
                'code' => [__('candidate_code_not_found', ['code' => $code])],
            ]);
        }

        $mock = $student->mock;

        if (! $mock || $mock->active != 1) {
            if ($request->isMethod('get')) {
                return redirect('/?error='.urlencode(__('mock_inactive')));
            }
            throw ValidationException::withMessages([
                'code' => [__('mock_inactive')],
            ]);
        }

        if ($mock->require_desktop) {
            $message = __('mock_desktop_only');
            if ($request->isMethod('get')) {
                return redirect('/?error='.urlencode($message));
            }
            throw ValidationException::withMessages([
                'code' => [$message],
            ]);
        }

        $now = now();

        if ($mock->started_at && $now->lt(Carbon::parse($mock->started_at))) {
            $formattedStart = Carbon::parse($mock->started_at)->format('d.m.Y H:i');
            if ($request->isMethod('get')) {
                return redirect('/?error='.urlencode(__('mock_not_started', ['time' => $formattedStart])));
            }
            throw ValidationException::withMessages([
                'code' => [__('mock_not_started', ['time' => $formattedStart])],
            ]);
        }

        if ($mock->finished_at && $now->gt(Carbon::parse($mock->finished_at))) {
            $formattedFinish = Carbon::parse($mock->finished_at)->format('d.m.Y H:i');
            if ($request->isMethod('get')) {
                return redirect('/?error='.urlencode(__('mock_finished', ['time' => $formattedFinish])));
            }
            throw ValidationException::withMessages([
                'code' => [__('mock_finished', ['time' => $formattedFinish])],
            ]);
        }

        // Mark candidate as attended
        if (! $student->attended) {
            $student->attended = true;
            $student->save();
        }

        if (! $student->checked_in_at) {
            $student->checked_in_at = now();
            $student->save();
        }

        $attempt = $exam->findOrCreateMockAttempt($student, ['user_id' => Auth::check() ? Auth::id() : null]);
        if (! $attempt) {
            throw ValidationException::withMessages([
                'code' => [__('mock_inactive')],
            ]);
        }

        // Save session for guest student candidate access
        session([
            'mock_student_id' => $student->id,
            'mock_attempt_id' => $attempt->id,
        ]);

        return redirect()->route('practice.index', ['attempt_id' => $attempt->id]);
    }
}
