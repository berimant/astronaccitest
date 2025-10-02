<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UpdateProfileRequest;
use App\Http\Requests\Api\ChangePasswordRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Hash; 
use Illuminate\Support\Str; // Import Str untuk string helper

class UserController extends Controller
{
    // GET /api/user/me
    public function getAuthenticatedUser(Request $request)
    {
        return new UserResource($request->user());
    }

    // POST /api/user/profile
    public function updateProfile(UpdateProfileRequest $request)
    {
        $user = $request->user();
        
        $user->update($request->validated());

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => new UserResource($user)
        ]);
    }
    
    // POST /api/user/avatar (Upload Avatar)
    public function updateAvatar(Request $request)
    {
        $request->validate([
            'avatar' => 'required|image|mimes:jpeg,png,jpg|max:2048', 
        ]);

        $user = $request->user();

        // --- START PERBAIKAN KRITIS UNTUK CACHING ---
        // 1. Dapatkan file dan extension
        $file = $request->file('avatar');
        $extension = $file->getClientOriginalExtension();
        
        // 2. Buat nama file yang benar-benar unik menggunakan UUID
        $fileName = Str::uuid() . '.' . $extension; 
        
        // 3. Simpan file dengan nama unik ke folder 'public/avatars'
        // storeAs akan memastikan path yang disimpan di DB adalah 'public/avatars/nama_unik.jpg'
        $path = $file->storeAs('public/avatars', $fileName); 
        
        // 4. Hapus file lama jika ada
        if ($user->avatar_path && Storage::exists($user->avatar_path)) {
            Storage::delete($user->avatar_path);
        }
        // --- END PERBAIKAN KRITIS UNTUK CACHING ---

        // 5. Update path baru di database
        $user->update(['avatar_path' => $path]);
        
        $user->refresh(); 

        return response()->json([
            'message' => 'Avatar updated successfully.',
            'user' => new UserResource($user)
        ]);
    }

    // POST /api/user/password (Ganti Password)
    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $user = $request->user();
        
        // Validasi password lama sudah dilakukan di ChangePasswordRequest
        
        $user->update([
            'password' => Hash::make($request->password)
        ]);

        return response()->json([
            'message' => 'Password berhasil diubah. Silakan login ulang untuk keamanan.',
            'status_code' => 200
        ]);
    }

    // GET /api/users (List User + Pagination)
    public function index(Request $request)
    {
        $users = User::paginate($request->get('limit', 15)); 
        return UserResource::collection($users); 
    }

    // GET /api/users/search?q=query
    public function search(Request $request)
    {
        $query = $request->validate(['q' => 'required|string|min:1'])['q'];
        
        $users = User::where('name', 'like', "%{$query}%")
                     ->orWhere('email', 'like', "%{$query}%")
                     ->paginate($request->get('limit', 15));
                     
        return UserResource::collection($users);
    }

    // GET /api/users/{user} (Detail User - Route Model Binding)
    public function show(User $user)
    {
        return new UserResource($user);
    }
}
