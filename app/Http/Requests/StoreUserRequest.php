<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class StoreUserRequest extends FormRequest
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
            'user_id' => Auth::id(),
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
            'user_id' => 'nullable|integer|exists:users,id',
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:20|unique:users,phone',
            'role' => 'nullable|string',
            'email' => 'nullable|email|unique:users,email',
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
