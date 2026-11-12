<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * One OpenAI / Gemini API call (written by App\Support\AiUsage). Not center-scoped: only the Reports /
 * Usage pages read it, each filtering by owner_id explicitly.
 */
class AiUsageLog extends Model
{
    public const UPDATED_AT = null;

    public const PURPOSE_WRITING_EVAL = 'writing_eval';

    public const PURPOSE_PDF_IMPORT = 'pdf_import';

    public const PURPOSE_OTHER = 'other';

    public const PURPOSES = [self::PURPOSE_WRITING_EVAL, self::PURPOSE_PDF_IMPORT, self::PURPOSE_OTHER];

    protected $fillable = [
        'owner_id',
        'user_id',
        'provider',
        'model',
        'purpose',
        'input_tokens',
        'output_tokens',
        'estimated_cost_usd',
        'attempt_answer_id',
        'test_import_id',
        'created_at',
    ];

    protected $casts = [
        'input_tokens' => 'integer',
        'output_tokens' => 'integer',
        'estimated_cost_usd' => 'decimal:6',
        'created_at' => 'datetime',
    ];
}
