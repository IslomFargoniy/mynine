<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * - center_billable_candidates: an immutable billing record written the first time a mock candidate's attempt
 *   starts a written module (Listening / Reading / Writing). Monthly reports count these rows, so deleting a
 *   mock, candidate or attempt afterwards no longer lowers the bill. No foreign keys on purpose: the row must
 *   outlive what it describes. Backfilled from the live data (same rule as the old report query).
 * - attempts.owner_id: the center of a mock attempt, kept when the mock is deleted (the attempt no longer
 *   drops into the practice / Mynine bucket). Backfilled from the mock.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('center_billable_candidates', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('owner_id');
            $table->unsignedBigInteger('mock_student_id')->nullable()->unique();
            $table->unsignedBigInteger('mock_id')->nullable()->index();
            $table->unsignedBigInteger('attempt_id')->nullable();
            $table->string('code');
            $table->string('name');
            $table->string('mock_name')->nullable();
            $table->dateTime('counted_at');
            $table->timestamp('created_at')->nullable();

            $table->index(['owner_id', 'counted_at']);
            $table->index('counted_at');
        });

        Schema::table('attempts', function (Blueprint $table) {
            $table->unsignedBigInteger('owner_id')->nullable()->after('mock_student_id')->index();
        });

        DB::table('attempts')->whereNotNull('mock_id')->update([
            'owner_id' => DB::raw('(SELECT mocks.owner_id FROM mocks WHERE mocks.id = attempts.mock_id)'),
        ]);

        $billed = DB::table('mock_students')
            ->join('mocks', 'mocks.id', '=', 'mock_students.mock_id')
            ->join('attempts', 'attempts.mock_student_id', '=', 'mock_students.id')
            ->whereColumn('attempts.mock_id', 'mocks.id')
            ->whereNotNull('mocks.owner_id')
            ->whereExists(fn ($q) => $q->selectRaw('1')
                ->from('attempt_types')
                ->join('types', 'types.id', '=', 'attempt_types.type_id')
                ->whereColumn('attempt_types.attempt_id', 'attempts.id')
                ->whereIn('types.name', ['Listening', 'Reading', 'Writing']))
            ->orderBy('attempts.id')
            ->get([
                'mocks.owner_id', 'mock_students.id as mock_student_id', 'mocks.id as mock_id', 'attempts.id as attempt_id',
                'mock_students.code', 'mock_students.name', 'mocks.name as mock_name',
                DB::raw('COALESCE(attempts.started_at, attempts.created_at) as counted_at'),
            ]);

        foreach ($billed->unique('mock_student_id')->chunk(500) as $chunk) {
            DB::table('center_billable_candidates')->insertOrIgnore($chunk->map(fn ($row) => [
                'owner_id' => $row->owner_id,
                'mock_student_id' => $row->mock_student_id,
                'mock_id' => $row->mock_id,
                'attempt_id' => $row->attempt_id,
                'code' => (string) $row->code,
                'name' => (string) $row->name,
                'mock_name' => $row->mock_name,
                'counted_at' => $row->counted_at ?? now(),
                'created_at' => now(),
            ])->values()->all());
        }
    }

    public function down(): void
    {
        Schema::table('attempts', function (Blueprint $table) {
            $table->dropIndex(['owner_id']);
            $table->dropColumn('owner_id');
        });

        Schema::dropIfExists('center_billable_candidates');
    }
};
