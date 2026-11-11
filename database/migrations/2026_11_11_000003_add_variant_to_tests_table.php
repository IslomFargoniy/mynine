<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * IELTS variant of a test: Academic or General Training (Reading uses a different band table).
     */
    public function up(): void
    {
        Schema::table('tests', function (Blueprint $table) {
            $table->string('variant', 16)->default('academic');
        });
    }

    public function down(): void
    {
        Schema::table('tests', function (Blueprint $table) {
            $table->dropColumn('variant');
        });
    }
};
