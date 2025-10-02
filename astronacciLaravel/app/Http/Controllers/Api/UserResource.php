<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage; // Digunakan untuk menghasilkan URL Avatar

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Pastikan Anda memiliki kolom 'avatar_path' di model User dan di tabel database.
        
        return [
            // Field Wajib
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            
            // Field Nilai Plus: Avatar URL
            // Ini akan memastikan aplikasi Flutter menerima URL yang lengkap dan dapat diakses publik.
            'avatar_url' => $this->avatar_path ? url(Storage::url($this->avatar_path)) : null,
            
            // Field Tambahan (Opsional, tapi bagus untuk informasi)
            'created_at' => $this->created_at->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at->format('Y-m-d H:i:s'),
        ];
    }
}