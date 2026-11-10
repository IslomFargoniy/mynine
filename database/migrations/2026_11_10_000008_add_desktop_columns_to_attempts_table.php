<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attempts', function (Blueprint $table) {
            $table->foreignId('device_id')->nullable()->after('mock_student_id')->constrained('devices')->nullOnDelete();
            $table->dateTime('last_heartbeat_at')->nullable();
            $table->dateTime('paused_at')->nullable();
            $table->dateTime('unlock_requested_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('attempts', function (Blueprint $table) {
            $table->dropForeign(['device_id']);
            $table->dropColumn(['device_id', 'last_heartbeat_at', 'paused_at', 'unlock_requested_at']);
        });
    }
};
