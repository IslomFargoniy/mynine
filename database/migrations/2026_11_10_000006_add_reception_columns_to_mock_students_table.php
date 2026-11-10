<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mock_students', function (Blueprint $table) {
            $table->dateTime('checked_in_at')->nullable()->after('phone');
            $table->dateTime('speaking_at')->nullable()->after('checked_in_at');
            $table->dateTime('result_printed_at')->nullable()->after('speaking_at');
            $table->dateTime('result_delivered_at')->nullable()->after('result_printed_at');
            $table->foreignId('delivered_by')->nullable()->after('result_delivered_at')->constrained('users')->nullOnDelete();
            $table->index('phone');
        });
    }

    public function down(): void
    {
        Schema::table('mock_students', function (Blueprint $table) {
            $table->dropForeign(['delivered_by']);
            $table->dropIndex(['phone']);
            $table->dropColumn(['checked_in_at', 'speaking_at', 'result_printed_at', 'result_delivered_at', 'delivered_by']);
        });
    }
};
