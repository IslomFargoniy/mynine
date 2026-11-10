<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mock Bank "Import from PDF": one row per upload, with a status per module
 * (queued / running / done / failed + warnings) that the Mock Bank card polls.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('test_imports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('test_id')->constrained('tests')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 20)->default('queued');
            $table->boolean('replace')->default(false);
            $table->json('files')->nullable();
            $table->json('modules')->nullable();
            $table->timestamp('finished_at')->nullable();
            $table->timestamps();

            $table->index(['test_id', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('test_imports');
    }
};
