<?php

namespace App\Http\Controllers;

use App\Models\Mock;
use App\Models\MockStudent;
use App\Services\ExamService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class MockStudentController extends Controller
{
    /**
     * Store new student candidates for a mock (Single or Bulk names)
     */
    public function store(Request $request)
    {
        $request->validate([
            'mock_id' => 'required|exists:mocks,id',
            'names' => 'required|string', // Single name or newline/comma separated names
            'phone' => 'nullable|string',
        ]);

        $mock = Mock::findOrFail($request->mock_id);
        $this->authorize('manageStudents', $mock);

        $rawList = preg_split('/[\r\n,]+/', $request->names);
        $names = [];
        foreach ($rawList as $rawName) {
            $name = trim($rawName);
            if (! empty($name)) {
                $names[] = $name;
            }
        }

        if (empty($names)) {
            return back()->with('error', "Hech qanday o'quvchi qo'shilmadi.");
        }

        $codes = MockStudent::generateBulkCodes(count($names), $mock->name);
        $now = now();
        $records = [];

        for ($i = 0; $i < count($names); $i++) {
            $records[] = [
                'mock_id' => $mock->id,
                'name' => $names[$i],
                'code' => $codes[$i],
                'phone' => $request->phone ?? null,
                'attended' => false,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        MockStudent::insert($records);

        $createdCount = count($records);

        return back()->with('success', "{$createdCount} ta o'quvchi muvaffaqiyatli qo'shildi!");
    }

    /**
     * Delete candidate student
     */
    public function destroy(MockStudent $mockStudent)
    {
        $this->authorize('manageStudents', $mockStudent->mock);

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
