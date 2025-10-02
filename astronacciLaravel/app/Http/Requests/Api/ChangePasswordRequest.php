<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Hash; // PASTIKAN BARIS INI ADA
use Illuminate\Validation\ValidationException;

class ChangePasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() != null;
    }

    public function rules(): array
    {
        return [
            // Harus memasukkan password lama untuk verifikasi keamanan
            'current_password' => ['required', 'string'], 
            // Password baru minimal 8 karakter dan harus dikonfirmasi
            'password' => ['required', 'string', 'min:8', 'confirmed'], 
        ];
    }
    
    // Validasi kustom untuk memastikan password lama benar
    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            // Jika pengguna tidak ada atau password tidak cocok
            if ($this->user() && !Hash::check($this->current_password, $this->user()->password)) {
                $validator->errors()->add('current_password', 'Password lama yang Anda masukkan salah.');
            }
        });
    }
}
