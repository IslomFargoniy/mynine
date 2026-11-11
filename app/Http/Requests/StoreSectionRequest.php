<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreSectionRequest extends FormRequest
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
            'part_id' => 'required|exists:parts,id',
            'question_type_id' => 'required|exists:question_types,id',
            'textarea' => 'required|string',
            'from_option' => 'nullable|string|max:4',
            'to_option' => 'nullable|string|max:4',
        ];
    }

    protected function prepareForValidation()
    {
        $this->merge([
            'from_option' => $this->from_option ? strtolower($this->from_option) : null,
            'to_option' => $this->to_option ? strtolower($this->to_option) : null,
        ]);
    }
}
