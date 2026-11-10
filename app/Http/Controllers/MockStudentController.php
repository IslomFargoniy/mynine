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
     */
    public function store(Request $request, CandidateService $candidates)
    {
        $request->validate([
            'mock_id' => 'required|exists:mocks,id',
            'candidates' => 'required|array|min:1|max:500',
            'candidates.*.name' => 'required|string|max:255',
            'candidates.*.phone' => 'required|string|max:32',
        ]);

        $mock = Mock::findOrFail($request->mock_id);
        $this->authorize('manageStudents', $mock);

        $rows = [];
        $errors = [];
        foreach (array_values($request->input('candidates')) as $i => $candidate) {
            $phone = CandidateService::normalizePhone($candidate['phone'] ?? null);
            if ($phone === null) {
                $errors["candidates.{$i}.phone"] = "Telefon raqami noto'g'ri: ".($candidate['phone'] ?? '').' (+998XXXXXXXXX)';

                continue;
            }
            $rows[] = ['name' => trim($candidate['name']), 'phone' => $phone];
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }

        $codes = MockStudent::generateBulkCodes(count($rows), $mock->name);
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

        $response = back()->with('success', count($rows)." ta nomzod qo'shildi.");

        return $repeats->isEmpty()
            ? $response
            : $response->with('warning', 'Diqqat, bu modullarni avval topshirgan: '.$repeats->implode(', '));
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

        abort_if($students->isEmpty(), 404, 'Nomzodlar topilmadi.');

        return Pdf::render('pdf.code-cards', compact('mock', 'students'), 'Codes_'.$mock->id);
    }

    /**
     * Delete candidate (Admin)
     */
    public function destroy(MockStudent $mockStudent)
    {
        $this->authorize('deleteStudents', $mockStudent->mock);

        $mockStudent->delete();

        return back()->with('success', "O'quvchi o'chirildi.");
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
                return redirect('/?error='.urlencode("Kiritilgan kod ({$code}) topilmadi!"));
            }
            throw ValidationException::withMessages([
                'code' => ["Kiritilgan kod ({$code}) topilmadi!"],
            ]);
        }

        $mock = $student->mock;

        if (! $mock || $mock->active != 1) {
            if ($request->isMethod('get')) {
                return redirect('/?error='.urlencode('Ushbu Mock test hozirda faol emas!'));
            }
            throw ValidationException::withMessages([
                'code' => ['Ushbu Mock test hozirda faol emas!'],
            ]);
        }

        if ($mock->require_desktop) {
            $message = 'Ushbu Mock test faqat Mynine Desktop ilovasi orqali topshiriladi. Imtihon kompyuteridagi ilovaga kodingizni kiriting.';
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
                return redirect('/?error='.urlencode("Ushbu Mock test hali boshlanmagan! Boshlanish vaqti: {$formattedStart}"));
            }
            throw ValidationException::withMessages([
                'code' => ["Ushbu Mock test hali boshlanmagan! Boshlanish vaqti: {$formattedStart}"],
            ]);
        }

        if ($mock->finished_at && $now->gt(Carbon::parse($mock->finished_at))) {
            $formattedFinish = Carbon::parse($mock->finished_at)->format('d.m.Y H:i');
            if ($request->isMethod('get')) {
                return redirect('/?error='.urlencode("Ushbu Mock test vaqti tugagan! Yakunlangan vaqti: {$formattedFinish}"));
            }
            throw ValidationException::withMessages([
                'code' => ["Ushbu Mock test vaqti tugagan! Yakunlangan vaqti: {$formattedFinish}"],
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
                'code' => ['Ushbu Mock test hozirda faol emas!'],
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
