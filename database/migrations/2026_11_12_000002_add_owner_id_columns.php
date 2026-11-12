<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Step 1 of 3 (columns → backfill → foreign keys): nullable owner_id (= the center's Admin user) on every
 * center-owned table. mock_students, mock_modules and attempts are owned through their mock.
 * users.owner_id marks Reception staff of a center; users.suspended_at blocks a staff login.
 * PC numbers become unique per center instead of globally.
 */
return new class extends Migration
{
    private const TABLES = ['mocks', 'devices', 'tests', 'test_imports'];

    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('owner_id')->nullable()->after('user_id')->index();
            $table->timestamp('suspended_at')->nullable();
        });

        foreach (self::TABLES as $name) {
            Schema::table($name, function (Blueprint $table) {
                $table->unsignedBigInteger('owner_id')->nullable()->after('id')->index();
            });
        }

        Schema::table('mocks', function (Blueprint $table) {
            $table->index(['owner_id', 'started_at']);
        });

        Schema::table('devices', function (Blueprint $table) {
            $table->dropUnique(['number']);
            $table->unique(['owner_id', 'number']);
        });
    }

    public function down(): void
    {
        Schema::table('devices', function (Blueprint $table) {
            $table->dropUnique(['owner_id', 'number']);
            $table->unique(['number']);
        });

        Schema::table('mocks', function (Blueprint $table) {
            $table->dropIndex(['owner_id', 'started_at']);
        });

        foreach (self::TABLES as $name) {
            Schema::table($name, function (Blueprint $table) {
                $table->dropIndex(['owner_id']);
                $table->dropColumn('owner_id');
            });
        }

        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['owner_id']);
            $table->dropColumn(['owner_id', 'suspended_at']);
        });
    }
};
