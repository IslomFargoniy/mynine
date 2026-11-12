<?php

namespace App\Support;

use App\Models\AiUsageLog;
use Closure;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Records every OpenAI / Gemini call in ai_usage_logs. The services call record() with the token counts
 * of the API response; the caller that knows what the call is for (the Writing evaluation job, the PDF
 * import job, ...) wraps the work in during() with the center (owner_id), user, purpose and related ids.
 *
 * Never throws: a failed log write must not break an evaluation or an import.
 */
class AiUsage
{
    /** @var array<int, array<string, mixed>> */
    private array $stack = [];

    /**
     * Run $callback with this context for the AI calls made inside it.
     *
     * @template T
     *
     * @param  array{owner_id?: ?int, user_id?: ?int, purpose?: string, attempt_answer_id?: ?int, test_import_id?: ?int}  $context
     * @param  Closure(): T  $callback
     * @return T
     */
    public function during(array $context, Closure $callback): mixed
    {
        $this->stack[] = $context;

        try {
            return $callback();
        } finally {
            array_pop($this->stack);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function context(): array
    {
        return $this->stack === [] ? [] : end($this->stack);
    }

    public function record(string $provider, string $model, int $inputTokens, int $outputTokens): ?AiUsageLog
    {
        $context = $this->context();
        $purpose = (string) ($context['purpose'] ?? AiUsageLog::PURPOSE_OTHER);

        try {
            return AiUsageLog::create([
                'owner_id' => $context['owner_id'] ?? null,
                'user_id' => $context['user_id'] ?? null,
                'provider' => $provider,
                'model' => mb_substr($model, 0, 100),
                'purpose' => in_array($purpose, AiUsageLog::PURPOSES, true) ? $purpose : AiUsageLog::PURPOSE_OTHER,
                'input_tokens' => max(0, $inputTokens),
                'output_tokens' => max(0, $outputTokens),
                'estimated_cost_usd' => self::estimateCost($model, $inputTokens, $outputTokens),
                'attempt_answer_id' => $context['attempt_answer_id'] ?? null,
                'test_import_id' => $context['test_import_id'] ?? null,
                'created_at' => now(),
            ]);
        } catch (Throwable $e) {
            Log::warning('AI usage could not be recorded', ['provider' => $provider, 'model' => $model, 'error' => $e->getMessage()]);

            return null;
        }
    }

    /**
     * Estimated USD cost from config/ai_pricing.php ($ per 1M tokens); null for an unknown model.
     */
    public static function estimateCost(string $model, int $inputTokens, int $outputTokens): ?float
    {
        $price = self::price($model);
        if ($price === null) {
            return null;
        }

        return round(($inputTokens * (float) $price['input'] + $outputTokens * (float) $price['output']) / 1_000_000, 6);
    }

    /**
     * @return array{input: float|int, output: float|int}|null
     */
    public static function price(string $model): ?array
    {
        $models = (array) config('ai_pricing.models', []);
        $model = strtolower(trim($model));
        $model = str_starts_with($model, 'models/') ? substr($model, 7) : $model;

        if (isset($models[$model])) {
            return $models[$model];
        }

        $best = null;
        foreach (array_keys($models) as $key) {
            if (str_starts_with($model, (string) $key) && ($best === null || strlen((string) $key) > strlen($best))) {
                $best = (string) $key;
            }
        }

        return $best !== null ? $models[$best] : null;
    }
}
