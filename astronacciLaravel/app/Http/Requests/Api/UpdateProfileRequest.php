<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        // User harus sudah login untuk memperbarui profil
        return $this->user() != null;
    }

    public function rules(): array
    {
        // Ambil user yang sedang login untuk diabaikan saat cek keunikan email
        $user = $this->user(); 

        return [
            'name' => ['required', 'string', 'max:255'],
            // Email harus unik, KECUALI jika email tersebut adalah email milik user ini sendiri
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)], 
        ];
    }
}
