<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Desktop API v1.1 (docs/desktop/API.md "v1.1 changes"):
     * - attempt_answers.client_seq: per-question monotonic client counter (last-write-wins ordering).
     * - attempt_answers.late_synced: saved after the module ended because the PC was offline at the end.
     * - attempt_types.offline_at_end: whether the PC was offline when the module ended
     *   (snapshot of attempts.last_heartbeat_at < finished_at, taken before the next heartbeat).
     */
    public function up(): void
    {
        Schema::table('attempt_answers', function (Blueprint $table) {
            $table->unsignedBigInteger('client_seq')->nullable();
            $table->boolean('late_synced')->default(false);
        });

        Schema::table('attempt_types', function (Blueprint $table) {
            $table->boolean('offline_at_end')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('attempt_answers', function (Blueprint $table) {
            $table->dropColumn(['client_seq', 'late_synced']);
        });

        Schema::table('attempt_types', function (Blueprint $table) {
            $table->dropColumn('offline_at_end');
        });
    }
};
