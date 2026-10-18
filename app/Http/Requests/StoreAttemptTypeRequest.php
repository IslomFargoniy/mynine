<?php

namespace App\Http\Requests;

use App\Models\Type;
use Illuminate\Foundation\Http\FormRequest;

class StoreAttemptTypeRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        $type = Type::query()
            ->where('name', 'Speaking')
            ->first();

        $this->merge([
            'type_id' => $this->input('type_id', $type?->id), // default: Speaking (manual examiner score)
        ]);
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
            'type_id' => 'nullable|integer|exists:types,id',
            'score' => 'required|numeric|min:0|max:9',
            'comment' => 'nullable',
        ];
    }
}
