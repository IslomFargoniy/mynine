<?php

namespace App\Http\Requests;

use App\Models\Attempt;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreAttemptRequest extends FormRequest
{
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
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => 'required_with:mock_id|nullable|string|max:255',
            'mock_id' => 'nullable|exists:mocks,id',
            'test_id' => 'required|exists:tests,id',
            // Single-module practice (website Test Bank only, never with a mock).
            'module' => 'nullable|prohibits:mock_id|in:'.implode(',', array_keys(Attempt::PRACTICE_MODULES)),
        ];
    }
}
