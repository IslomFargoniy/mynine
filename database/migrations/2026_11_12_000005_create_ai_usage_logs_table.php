<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * One row per OpenAI / Gemini API call (App\Support\AiUsage): who it was for (owner_id = the center of the
 * related record; null = Mynine practice / platform), what for (purpose), the token counts from the API
 * response and the estimated cost from config/ai_pricing.php (null for an unknown model).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_usage_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('provider', 20);
            $table->string('model', 100);
            $table->string('purpose', 20)->default('other');
            $table->unsignedInteger('input_tokens')->default(0);
            $table->unsignedInteger('output_tokens')->default(0);
            $table->decimal('estimated_cost_usd', 12, 6)->nullable();
            $table->unsignedBigInteger('attempt_answer_id')->nullable()->index();
            $table->unsignedBigInteger('test_import_id')->nullable()->index();
            $table->timestamp('created_at')->nullable()->index();

            $table->index(['owner_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_usage_logs');
    }
};
