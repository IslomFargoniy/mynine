<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mocks', function (Blueprint $table) {
            // Kept for legacy single-test mocks; module mocks use mock_modules.
            $table->unsignedBigInteger('test_id')->nullable()->change();

            $table->boolean('require_desktop')->default(false)->after('active');
            $table->dateTime('speaking_starts_at')->nullable()->after('require_desktop');
            $table->unsignedSmallInteger('speaking_slot_minutes')->default(15)->after('speaking_starts_at');
        });
    }

    public function down(): void
    {
        Schema::table('mocks', function (Blueprint $table) {
            $table->dropColumn(['require_desktop', 'speaking_starts_at', 'speaking_slot_minutes']);
        });
    }
};
