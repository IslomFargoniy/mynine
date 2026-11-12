<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A PC is identified by (center, machine_id): registering with another center's machine_id no longer takes
 * the row over (the API refuses with 409 device_other_center). machine_id was globally unique, so existing
 * rows already satisfy the new index.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('devices', function (Blueprint $table) {
            $table->unique(['owner_id', 'machine_id']);
            $table->index('machine_id');
        });

        Schema::table('devices', function (Blueprint $table) {
            $table->dropUnique(['machine_id']);
        });
    }

    public function down(): void
    {
        Schema::table('devices', function (Blueprint $table) {
            $table->unique(['machine_id']);
        });

        Schema::table('devices', function (Blueprint $table) {
            $table->dropIndex(['machine_id']);
            $table->dropUnique(['owner_id', 'machine_id']);
        });
    }
};
