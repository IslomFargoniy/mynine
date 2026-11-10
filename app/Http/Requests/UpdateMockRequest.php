<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ValidatesMockModules;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateMockRequest extends FormRequest
{
    use ValidatesMockModules;

    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * Legacy single-test mocks (no modules) may still be saved without modules.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $mock = $this->route('mock');
        $legacy = $mock && $mock->test_id && ! $mock->modules()->exists();

        return [
            'name' => 'required|string|max:255',
            'comment' => 'nullable|string',
            'started_at' => 'required|date|date_format:Y-m-d H:i|before:finished_at',
            'finished_at' => 'required|date|date_format:Y-m-d H:i|after:started_at',
            'active' => 'nullable|boolean',
            ...$this->moduleRules(required: ! $legacy),
        ];
    }
}
