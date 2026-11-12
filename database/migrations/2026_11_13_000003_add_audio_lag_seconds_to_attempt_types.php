<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Listening audio missed while the exam app was closed / restarting. The desktop app resumes the recording where
 * it stopped and the module's finished_at moves forward by the same amount (ExamService::extendForAudioLag).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attempt_types', function (Blueprint $table) {
            $table->unsignedInteger('audio_lag_seconds')->default(0)->after('offline_at_end');
        });
    }

    public function down(): void
    {
        Schema::table('attempt_types', function (Blueprint $table) {
            $table->dropColumn('audio_lag_seconds');
        });
    }
};
