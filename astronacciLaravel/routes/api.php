<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
| SEMUA ROUTE DI SINI SECARA OTOMATIS BERPREFIX /api
*/

// --- Public Endpoints (Form Register, Login & Lupa Password) ---
// Akses: POST /api/register
Route::post('register', [AuthController::class, 'register']); 
// Akses: POST /api/login
Route::post('login', [AuthController::class, 'login']); 
// Akses: POST /api/forgot-password
Route::post('forgot-password', [AuthController::class, 'forgotPassword']);

// --- Protected Endpoints (Requires sanctum token) ---
Route::middleware('auth:sanctum')->group(function () {

    // 1. Profile & Avatar (Akses: /api/user/...)
    Route::prefix('user')->group(function () {
        Route::get('me', [UserController::class, 'getAuthenticatedUser']); 
        Route::post('profile', [UserController::class, 'updateProfile']); 
        Route::post('avatar', [UserController::class, 'updateAvatar']); 
    });

    // 2. User Listing (Akses: /api/users/...)
    Route::get('users', [UserController::class, 'index']); 
    Route::get('users/search', [UserController::class, 'search']); 
    Route::get('users/{user}', [UserController::class, 'show']); 
    Route::post('/user/password', [UserController::class, 'changePassword']); 
   
    // 3. Logout (Akses: /api/logout)
    Route::post('logout', [AuthController::class, 'logout']); 

    
    
    // Default Route /api/user (Bisa dihapus jika sudah ada 'user/me')
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
