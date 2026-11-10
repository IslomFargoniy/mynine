<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attempt_violations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('attempt_id')->constrained('attempts')->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained('devices')->nullOnDelete();
            // Idempotency key sent by the desktop app (retries must not duplicate rows).
            $table->string('client_uuid', 64)->nullable();
            $table->string('type', 40);
            $table->json('detail')->nullable();
            $table->dateTime('occurred_at');
            $table->timestamps();

            $table->index('attempt_id');
            $table->unique(['attempt_id', 'client_uuid']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attempt_violations');
    }
};
