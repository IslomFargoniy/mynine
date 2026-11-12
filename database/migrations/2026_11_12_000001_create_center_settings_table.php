<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Multi-center tenancy: a center IS its Admin user. Per-center settings live here, one row per Admin
 * (owner_id = users.id): name, logo, short code (desktop registration), status, contract end, and the
 * desktop settings that used to be global (center password bcrypt + offline PBKDF2, exam-app background).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('center_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_id')->unique()->constrained('users')->restrictOnDelete();
            $table->string('name');
            $table->string('code', 12)->unique();
            $table->string('logo_path')->nullable();
            $table->string('status', 20)->default('active');
            $table->date('contract_until')->nullable();
            $table->string('exit_password')->nullable();
            $table->string('exit_password_offline')->nullable();
            $table->timestamp('exit_password_updated_at')->nullable();
            $table->text('background')->nullable();
            $table->timestamp('background_updated_at')->nullable();
            $table->timestamps();
        });

        Schema::create('center_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->unsignedBigInteger('center_id')->nullable()->index();
            $table->string('action', 40);
            $table->string('old_email')->nullable();
            $table->string('new_email')->nullable();
            $table->json('meta')->nullable();
            $table->string('ip', 45)->nullable();
            $table->timestamp('created_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('center_audit_logs');
        Schema::dropIfExists('center_settings');
    }
};
