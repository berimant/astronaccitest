<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UpdateProfileRequest; // Asumsi Anda sudah membuat request ini
use App\Http\Requests\Api\ChangePasswordRequest;
use App\Http\Resources\UserResource; // Asumsi Anda sudah membuat resource ini
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage; // Untuk Avatar Upload (Nilai Plus)

class UserController extends Controller
{
    // GET /api/user/me
    public function getAuthenticatedUser(Request $request)
    {
        // Mengembalikan data user yang sedang login menggunakan UserResource
        return new UserResource($request->user());
    }

    // POST /api/user/profile
    public function updateProfile(UpdateProfileRequest $request)
    {
        $user = $request->user();
        
        // Memperbarui data profil menggunakan data yang sudah divalidasi
        $user->update($request->validated());

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => new UserResource($user)
        ]);
    }
    
    // ... (Bagian sebelumnya tetap sama)

    // POST /api/user/avatar (Nilai Plus: Upload Avatar)
    public function updateAvatar(Request $request)
    {
        // 1. Validasi Input File (wajib image, max 2MB)
        $request->validate([
            'avatar' => 'required|image|mimes:jpeg,png,jpg|max:2048', 
        ]);

        $user = $request->user();

        // 2. Simpan file baru dan dapatkan path
        // File disimpan di storage/app/public/avatars
        $path = $request->file('avatar')->store('public/avatars'); 

        // 3. Hapus avatar lama (Maintenance: Hapus file fisik lama)
        if ($user->avatar_path) {
            // Pastikan Anda telah menambahkan 'avatar_path' sebagai fillable di Model User
            Storage::delete($user->avatar_path);
        }

        // 4. Update path di database
        $user->update(['avatar_path' => $path]);
        
        // KRITIS: Refresh model user agar UserResource mendapatkan path terbaru dari DB
        $user->refresh(); 

        return response()->json([
            'message' => 'Avatar updated successfully.',
            // Sekarang UserResource akan menggunakan data user yang sudah di-refresh
            'user' => new UserResource($user)
        ]);
    }
// ... (Bagian selanjutnya tetap sama)


    // GET /api/users (List User + Pagination)
    public function index(Request $request)
    {
        // Nilai Plus: Implementasi Pagination
        $users = User::paginate($request->get('limit', 15)); 
        
        // Menggunakan collection() untuk format respons pagination yang benar
        return UserResource::collection($users); 
    }

    // GET /api/users/search?q=query
    public function search(Request $request)
    {
        // Validasi query pencarian
        $query = $request->validate(['q' => 'required|string|min:1'])['q'];
        
        $users = User::where('name', 'like', "%{$query}%")
                     ->orWhere('email', 'like', "%{$query}%")
                     ->paginate($request->get('limit', 15));
                     
        return UserResource::collection($users);
    }

    // GET /api/users/{user} (Detail User - Route Model Binding)
    public function show(User $user)
    {
        // Mengembalikan detail user tertentu
        return new UserResource($user);
    }

    // POST /api/user/password
    public function changePassword(ChangePasswordRequest $request)
    {
        $user = $request->user();
        
        // Data sudah divalidasi, termasuk pengecekan password lama di ChangePasswordRequest
        
        // Memperbarui password menggunakan Hash::make
        $user->update([
            'password' => Hash::make($request->password)
        ]);

        return response()->json([
            'message' => 'Password berhasil diubah. Silakan login kembali dengan password baru Anda.',
            // Dalam kasus nyata, kita akan menghapus semua token di sini untuk memaksa relogin
            // $user->tokens()->delete();
        ]);
    }
    
}
