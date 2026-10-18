<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

class StoreMockRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'user_id' => auth()->id(),
            'slug' => Str::slug($this->name, '-').'-'.\Str::random(5),
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
            'name' => 'required|string|max:255',
            'comment' => 'nullable|string',
            'started_at' => 'required|date|date_format:Y-m-d H:i|before:finished_at',
            'finished_at' => 'required|date|date_format:Y-m-d H:i|after:started_at',
            'user_id' => 'required|exists:users,id',
            'test_id' => 'required|exists:tests,id',
            'slug' => 'required|string|max:255|unique:mocks,slug',
            'active' => 'nullable|boolean',
        ];

    }
}
