<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Practice of two modules together is stored as "listening,reading" (up to 26 chars). */
    public function up(): void
    {
        Schema::table('attempts', function (Blueprint $table) {
            $table->string('module', 32)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('attempts', function (Blueprint $table) {
            $table->string('module', 16)->nullable()->change();
        });
    }
};
