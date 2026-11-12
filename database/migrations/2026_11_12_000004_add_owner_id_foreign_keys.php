<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Step 3 of 3: foreign keys on owner_id, after the backfill. Admin users (centers) are never deleted, so
 * owned rows restrict deletion; a deleted staff user simply loses its link. SQLite (tests) skips this step:
 * it cannot add foreign keys to existing tables without rebuilding them.
 */
return new class extends Migration
{
    private const TABLES = ['mocks', 'devices', 'tests', 'test_imports'];

    public function up(): void
    {
        if (Schema::getConnection()->getDriverName() === 'sqlite') {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            $table->foreign('owner_id')->references('id')->on('users')->nullOnDelete();
        });

        foreach (self::TABLES as $name) {
            Schema::table($name, function (Blueprint $table) {
                $table->foreign('owner_id')->references('id')->on('users')->restrictOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() === 'sqlite') {
            return;
        }

        foreach ([...self::TABLES, 'users'] as $name) {
            Schema::table($name, function (Blueprint $table) {
                $table->dropForeign(['owner_id']);
            });
        }
    }
};
