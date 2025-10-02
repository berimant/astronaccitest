<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Http\Resources\UserResource; // Import UserResource untuk respons
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * POST /api/register
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        // Data sudah divalidasi oleh RegisterRequest
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        // Buat token Sanctum
        $token = $user->createToken("API-Token-{$user->id}")->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'user' => new UserResource($user), // Menyertakan UserResource
            'access_token' => $token,
            'token_type' => 'Bearer',
        ], 201);
    }

    /**
     * POST /api/login
     */
    public function login(LoginRequest $request): JsonResponse
    {
        // Otentikasi user menggunakan credential email dan password
        if (!Auth::attempt($request->only('email', 'password'))) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials.'],
            ])->status(401); // 401 Unauthorized
        }

        // Dapatkan objek user yang berhasil login
        $user = $request->user();

        // [Perbaikan] Tambahkan penghapusan token lama (praktik terbaik keamanan)
        $user->tokens()->delete(); 
        
        // Buat token baru
        $token = $user->createToken("API-Token-{$user->id}")->plainTextToken;

        return response()->json([
            'message' => 'Login successful.',
            'user' => new UserResource($user), // Menyertakan UserResource
            'access_token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    /**
     * POST /api/logout
     */
    public function logout(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();
        
        // Hapus token yang sedang digunakan
        $user->currentAccessToken()->delete();

        return response()->json(['message' => 'Logout successful.'], 200);
    }

    /**
     * POST /api/forgot-password
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        // Dalam konteks API, kita hanya mensimulasikan respons sukses
        $request->validate(['email' => 'required|email']);
        
        // Dalam aplikasi nyata, Anda akan menggunakan:
        // Password::sendResetLink($request->only('email'));

        return response()->json([
            'message' => 'Jika alamat email ada, link reset password telah dikirim.',
        ]);
    }
}
