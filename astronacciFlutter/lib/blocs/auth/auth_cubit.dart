import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
// Mengubah import path menjadi relatif untuk kompatibilitas struktur folder
import 'package:astronacci_test_flutter/models/user_model.dart'; 
import 'package:astronacci_test_flutter/services/api_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService;

  // >> PERBAIKAN: Tambahkan getter publik agar ApiService bisa diakses dari luar
  ApiService get apiService => _apiService;

  AuthCubit(this._apiService) : super(AuthInitial());

  // 1. Cek Status Otentikasi saat aplikasi dimulai
  void checkAuthStatus() async {
    final token = _apiService.getTokenFromPrefs();
    if (token != null) {
      try {
        // Coba ambil data user untuk validasi token
        final user = await _apiService.fetchAuthenticatedUser();
        // Dapatkan token lagi (jika API service menyimpan)
        final token = _apiService.getTokenFromPrefs(); 
        // FIX: Menyertakan token yang sudah didapatkan dari SharedPreferences
        emit(AuthAuthenticated(user: user, token: token!)); 
      } on DioException {
        // Jika token invalid (401), hapus token dan kembali ke Login
        _apiService.clearToken();
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  // 2. Login User
  Future<String?> login(String email, String password) async {
    emit(AuthLoading());
    
    // --- PERBAIKAN: Validasi Panjang Password Minimal 8 Karakter (Client-side) ---
    if (password.length < 8) {
      // Langsung kembalikan ke state Unauthenticated agar loading screen hilang.
      emit(AuthUnauthenticated()); 
      return 'Password harus minimal 8 karakter.';
    }

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      // FIX: Menyertakan response.user DAN response.token
      emit(AuthAuthenticated(user: response.user, token: response.token));
      return null; // Sukses
    } on DioException catch (e) {
      // --- PERBAIKAN KRITIS: Selalu kembali ke state Unauthenticated setelah gagal ---
      // Ini menghentikan loading screen di UI, memungkinkan form Login terlihat lagi.
      emit(AuthUnauthenticated()); 
      
      // Ambil pesan error dari respons Dio (misal: "Invalid credentials")
      return e.response?.data['message'] ?? 'Email atau password salah. Silakan coba lagi.';
    } catch (e) {
      // --- PERBAIKAN STUCK: Tangkap Exception generik (seperti "Invalid credentials")
      // dan reset state agar loading screen hilang.
      emit(AuthUnauthenticated()); 
      // Karena log menunjukkan "Invalid credentials", kita asumsikan ini adalah error umum login.
      return 'Email atau password salah. Silakan coba lagi.';
    }
  }

  // 3. Register User
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      // FIX: Menyertakan response.user DAN response.token
      emit(AuthAuthenticated(user: response.user, token: response.token));
      return null; // Sukses
    } on DioException catch (e) {
      emit(AuthUnauthenticated());
      // Ambil pesan error dari respons Dio (Laravel Validation)
      final errors = e.response?.data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.containsKey('email')) {
        return errors['email'][0]; // Ambil error pertama untuk email
      }
      return e.response?.data['message'] ?? 'Registrasi gagal, periksa data Anda.';
    } catch (e) {
      // Tambahkan penangkapan Exception generik untuk menghindari stuck loading saat register gagal.
      emit(AuthUnauthenticated());
      return 'Terjadi kesalahan tak terduga saat registrasi. Silakan coba lagi.';
    }
  }

  // 4. Lupa Password (Form Register, Login & Lupa Password)
  Future<String> forgotPassword(String email) async {
    try {
      await _apiService.forgotPassword(email);
      return 'Link reset password telah dikirim ke email Anda.';
    } on DioException catch (e) {
      // Menangani error jika email tidak ditemukan
      final errors = e.response?.data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.containsKey('email')) {
        return errors['email'][0];
      }
      return 'Gagal mengirim link reset password. Coba lagi nanti.';
    }
  }

  // 5. Logout User
  void logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Abaikan error logout dari server, yang penting token lokal dihapus
    } finally {
      emit(AuthUnauthenticated());
    }
  }

  // 6. Update User Profile (untuk dipanggil setelah Edit Profile berhasil)
  void updateUser(UserModel user) {
    if (state is AuthAuthenticated) {
      // Ambil token yang sudah ada di state
      final existingToken = (state as AuthAuthenticated).token;
      // FIX: Menyertakan user baru DAN token lama
      emit(AuthAuthenticated(user: user, token: existingToken));
    }
  }

 // --- KRITIS: Metode untuk memperbarui data user saat sudah login ---
  // Dipanggil setelah sukses update profile atau upload avatar
  void updateProfileUser(UserModel updatedUser) {
    if (state is AuthAuthenticated) {
      // Ambil token yang sudah ada dari state lama
      final existingToken = (state as AuthAuthenticated).token;
      
      // Emit state baru dengan model user yang diperbarui (fresh data)
      // FIX: Menyertakan user baru DAN token lama
      emit(AuthAuthenticated(user: updatedUser, token: existingToken));
      
      // State baru ini akan memicu rebuild pada ProfileScreen
    }
  }
}
