<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserRequest extends FormRequest
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
        $userId = $this->route('user'); // adjust depending on your route parameter name

        return [
            'name' => 'required|string|max:255',
            'phone' => [
                'nullable',
                'string',
                'max:20',
                Rule::unique('users', 'phone')->ignore($userId),
            ],
            'role' => 'nullable|string',
            'email' => [
                'nullable',
                'email',
                Rule::unique('users', 'email')->ignore($userId),
            ],
            'password' => 'nullable|string|min:6',
            'create_test_limit' => 'nullable|integer|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'The name field is required.',
        ];
    }
}
