<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('attempt_types', function (Blueprint $table) {
            $table->double('is_correct_count')->default(0)->after('score');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attempt_types', function (Blueprint $table) {
            $table->dropColumn('is_correct_count');
        });
    }
};
