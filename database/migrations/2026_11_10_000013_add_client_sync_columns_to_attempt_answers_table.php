<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Idempotency for the desktop answer queue: the last applied client change per answer.
     */
    public function up(): void
    {
        Schema::table('attempt_answers', function (Blueprint $table) {
            $table->string('client_uuid', 64)->nullable();
            $table->dateTime('client_changed_at', 3)->nullable();
            $table->index(['attempt_part_id', 'question_id']);
        });
    }

    public function down(): void
    {
        Schema::table('attempt_answers', function (Blueprint $table) {
            $table->dropIndex(['attempt_part_id', 'question_id']);
            $table->dropColumn(['client_uuid', 'client_changed_at']);
        });
    }
};
