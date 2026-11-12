<?php

namespace App\Http\Requests\Settings;

use App\Models\User\User;
use App\Rules\UniquePhone;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProfileUpdateRequest extends FormRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'digits_between:9,12', Rule::unique(User::class, 'phone')->ignore($this->user()->id), new UniquePhone($this->user()->id)],
            'username' => [
                'nullable',
                'string',
                'alpha_dash',
                'max:255',
                Rule::unique(User::class)->ignore($this->user()->id),
            ],

            'email' => [
                'nullable',
                'string',
                'lowercase',
                'email',
                'max:255',
                Rule::unique(User::class)->ignore($this->user()->id),
            ],
        ];
    }
}
