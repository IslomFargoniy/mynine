<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAttemptAnswerRequest extends FormRequest
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
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'attempt_id' => 'required|integer|exists:attempts,id',
            'part_id' => 'required|integer|exists:parts,id',
            'question_id' => 'required|exists:questions,id',
            'answer_text' => 'nullable|string',
            'options' => 'nullable|array',
            'options.*' => 'exists:options,id',
        ];
    }
}
