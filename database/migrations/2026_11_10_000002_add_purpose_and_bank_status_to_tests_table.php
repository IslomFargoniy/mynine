<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tests', function (Blueprint $table) {
            $table->string('purpose', 20)->default('practice')->after('open')->index();
            $table->string('bank_status', 20)->default('draft')->after('purpose');
        });

        // Every test used by a mock moves into the Mock Bank and is hidden from practice.
        $mockTestIds = DB::table('mocks')->whereNotNull('test_id')->distinct()->pluck('test_id');

        foreach ($mockTestIds->chunk(500) as $chunk) {
            DB::table('tests')->whereIn('id', $chunk->all())->update([
                'purpose' => 'mock',
                'open' => 0,
                'bank_status' => 'ready',
            ]);
        }
    }

    public function down(): void
    {
        Schema::table('tests', function (Blueprint $table) {
            $table->dropIndex(['purpose']);
            $table->dropColumn(['purpose', 'bank_status']);
        });
    }
};
