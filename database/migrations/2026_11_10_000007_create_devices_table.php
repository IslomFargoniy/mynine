<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->string('machine_id')->unique();
            $table->string('name');
            $table->string('token_hash', 64)->unique();
            $table->string('app_version', 40)->nullable();
            $table->string('os_version')->nullable();
            $table->string('ip', 45)->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->boolean('is_blocked')->default(false);
            // No FK: attempts reference devices, this is only a convenience pointer.
            $table->unsignedBigInteger('current_attempt_id')->nullable()->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};
