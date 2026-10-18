<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreOptionRequest extends FormRequest
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
            'section_id' => 'nullable|required_without:question_id|exists:sections,id',
            'question_id' => 'nullable|required_without:section_id|exists:questions,id',
            'textarea' => 'required|string|max:1000',
            'is_correct' => 'required|boolean',
        ];
    }
}
