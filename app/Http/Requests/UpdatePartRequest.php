<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdatePartRequest extends FormRequest
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
            'name' => 'required|string|max:255',
            'textarea' => 'nullable|string',
            'audio_path' => ['nullable', 'file', 'mimes:mp3,wav,ogg,m4a,aac,mpeg,mpga', 'max:24576'],
            'minute' => 'nullable|integer|min:0|max:180',
            'comment' => 'nullable|string|max:500',
        ];
    }
}
