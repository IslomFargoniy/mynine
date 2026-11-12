<?php

/*
|--------------------------------------------------------------------------
| AI pricing (USD per 1M tokens)
|--------------------------------------------------------------------------
|
| Used only to ESTIMATE the cost of each OpenAI / Gemini call in ai_usage_logs (Reports page). These are
| list prices (standard tier, no batch / cache discounts) as known in November 2026 and MUST be checked
| against the providers' pricing pages (platform.openai.com/docs/pricing, ai.google.dev/pricing) when they
| change or a new model is configured. The invoice of the provider is the real number.
|
| Lookup: exact model name first, then the longest key the returned model name starts with
| ("gpt-4o-mini-2024-07-18" -> "gpt-4o-mini"). A model that matches nothing gets a null cost.
| Gemini "thinking" tokens are billed (and counted here) as output tokens.
|
*/

return [
    'models' => [
        // OpenAI
        'gpt-4o-mini' => ['input' => 0.15, 'output' => 0.60],
        'gpt-4o' => ['input' => 2.50, 'output' => 10.00],
        'gpt-4.1-mini' => ['input' => 0.40, 'output' => 1.60],
        'gpt-4.1-nano' => ['input' => 0.10, 'output' => 0.40],
        'gpt-4.1' => ['input' => 2.00, 'output' => 8.00],
        'gpt-5-mini' => ['input' => 0.25, 'output' => 2.00],
        'gpt-5-nano' => ['input' => 0.05, 'output' => 0.40],
        'gpt-5' => ['input' => 1.25, 'output' => 10.00],

        // Google Gemini (prompts up to 200k tokens)
        'gemini-2.5-flash-lite' => ['input' => 0.10, 'output' => 0.40],
        'gemini-2.5-flash' => ['input' => 0.30, 'output' => 2.50],
        'gemini-2.5-pro' => ['input' => 1.25, 'output' => 10.00],
        'gemini-3-flash' => ['input' => 0.50, 'output' => 3.00],
        'gemini-3-pro' => ['input' => 2.00, 'output' => 12.00],
        // Default import model (services.gemini.import_model). Assumed equal to Gemini 3 Flash: CHECK.
        'gemini-3.5-flash' => ['input' => 0.50, 'output' => 3.00],
    ],
];
