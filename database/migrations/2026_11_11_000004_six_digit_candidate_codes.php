<?php

use App\Models\MockStudent;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Candidate codes become six digits only. Candidates who have not started yet get one: the digits after the
 * old "PREFIX-" (so "AVGUST17-697100" becomes "697100", matching the printed ticket) when they are free,
 * otherwise a new random code. Candidates with an attempt keep their code (results and history).
 */
return new class extends Migration
{
    public function up(): void
    {
        $taken = DB::table('mock_students')->pluck('code')->filter(fn ($c) => preg_match(MockStudent::CODE_PATTERN, (string) $c))->flip()->all();

        DB::table('mock_students')
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))->from('attempts')->whereColumn('attempts.mock_student_id', 'mock_students.id'))
            ->orderBy('id')
            ->get(['id', 'code'])
            ->each(function ($row) use (&$taken) {
                if (preg_match(MockStudent::CODE_PATTERN, (string) $row->code)) {
                    return;
                }

                $code = preg_match('/(\d{6})$/', (string) $row->code, $m) && ! isset($taken[$m[1]]) && (int) $m[1] >= 100000
                    ? $m[1]
                    : null;

                while ($code === null || isset($taken[$code])) {
                    $code = MockStudent::randomCode();
                }

                $taken[$code] = true;
                DB::table('mock_students')->where('id', $row->id)->update(['code' => $code]);
            });
    }

    public function down(): void
    {
        // Old prefixed codes are not restored (tickets are reprinted with the new ones).
    }
};
