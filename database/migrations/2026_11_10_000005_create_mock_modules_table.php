<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mock_modules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mock_id')->constrained('mocks')->cascadeOnDelete();
            $table->foreignId('type_id')->constrained('types');
            $table->foreignId('test_type_id')->constrained('test_types');
            $table->timestamps();

            $table->unique(['mock_id', 'type_id']);
        });

        // Existing mocks: one module per test_types row (that has parts) of the mock's test.
        $now = now();
        $mocks = DB::table('mocks')->whereNotNull('test_id')->get(['id', 'test_id']);

        foreach ($mocks as $mock) {
            $testTypes = DB::table('test_types')
                ->where('test_id', $mock->test_id)
                ->whereExists(fn ($q) => $q->select(DB::raw(1))->from('parts')->whereColumn('parts.test_type_id', 'test_types.id'))
                ->orderBy('id')
                ->get(['id', 'type_id']);

            $rows = [];
            foreach ($testTypes->unique('type_id') as $testType) {
                $rows[] = [
                    'mock_id' => $mock->id,
                    'type_id' => $testType->type_id,
                    'test_type_id' => $testType->id,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }

            if ($rows) {
                DB::table('mock_modules')->insert($rows);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('mock_modules');
    }
};
