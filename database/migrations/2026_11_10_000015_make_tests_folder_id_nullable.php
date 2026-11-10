<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Mock Bank tests do not live in folders: tests.folder_id becomes nullable and every existing
 * purpose=mock test is detached from its folder. The foreign key keeps its original behaviour
 * (restrict on delete, cascade on update).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tests', function (Blueprint $table) {
            $table->dropForeign(['folder_id']);
        });

        Schema::table('tests', function (Blueprint $table) {
            $table->unsignedBigInteger('folder_id')->nullable()->change();
            $table->foreign('folder_id')->references('id')->on('folders')
                ->restrictOnDelete()
                ->cascadeOnUpdate();
        });

        DB::table('tests')->where('purpose', 'mock')->update(['folder_id' => null]);
    }

    public function down(): void
    {
        if (DB::table('tests')->whereNull('folder_id')->exists()) {
            throw new RuntimeException('Some tests have no folder (Mock Bank). Move them into a folder before rolling back.');
        }

        Schema::table('tests', function (Blueprint $table) {
            $table->dropForeign(['folder_id']);
        });

        Schema::table('tests', function (Blueprint $table) {
            $table->unsignedBigInteger('folder_id')->nullable(false)->change();
            $table->foreign('folder_id')->references('id')->on('folders')
                ->restrictOnDelete()
                ->cascadeOnUpdate();
        });
    }
};
