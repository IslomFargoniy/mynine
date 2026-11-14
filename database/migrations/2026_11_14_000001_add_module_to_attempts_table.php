<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Single-module practice (Listening / Reading / Writing on their own). Null = the whole test, as every
     * attempt before this column.
     */
    public function up(): void
    {
        Schema::table('attempts', function (Blueprint $table) {
            $table->string('module', 16)->nullable()->after('test_id');
            $table->index(['user_id', 'module']);
        });
    }

    public function down(): void
    {
        Schema::table('attempts', function (Blueprint $table) {
            $table->dropIndex(['user_id', 'module']);
            $table->dropColumn('module');
        });
    }
};
