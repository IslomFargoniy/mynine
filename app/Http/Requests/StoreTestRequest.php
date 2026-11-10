<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class StoreTestRequest extends FormRequest
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
        $isMock = $this->input('purpose') === 'mock';

        $this->merge([
            // Mock Bank tests are never open for practice.
            'open' => $isMock ? 0 : (Auth::user()->hasRole('Admin') ? ($this->open ?? 0) : 0),
            'purpose' => $isMock ? 'mock' : 'practice',
            // Mock Bank tests never belong to a folder.
            'folder_id' => $isMock ? null : $this->input('folder_id'),
        ]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'folder_id' => ['nullable', 'required_unless:purpose,mock', 'exists:folders,id'],
            'name' => 'required|string|max:255',
            'comment' => 'nullable|string|max:500',
            'active' => 'nullable|boolean',
            'open' => 'nullable|boolean',
            'purpose' => 'required|in:practice,mock',
            'audio_path' => ['nullable', 'file', 'mimes:mp3,wav,ogg,m4a,aac,mpeg,mpga', 'max:24576'],
        ];
    }
}
