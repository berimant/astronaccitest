<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Fungsi untuk membuat URL Avatar yang bisa diakses publik
        $avatarUrl = $this->avatar_path 
            ? Storage::url($this->avatar_path) // Laravel akan membuat public URL
            : null;

        // Mengembalikan hanya field yang diperlukan oleh Flutter
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'avatar_url' => $avatarUrl,
            'created_at' => $this->created_at->format('Y-m-d H:i:s'),
        ];
    }
}
