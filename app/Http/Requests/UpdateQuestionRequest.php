<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateQuestionRequest extends FormRequest
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
            'textarea' => 'required|string',
            'answer_text' => 'nullable|string',
            'options' => 'nullable|array',
            'options.*.id' => 'nullable|integer',
            'options.*.textarea' => 'nullable|string',
            'options.*.is_correct' => 'nullable|boolean',
        ];
    }
}
