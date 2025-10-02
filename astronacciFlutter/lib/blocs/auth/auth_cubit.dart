import 'dart:io'; // KRITIS: Import File untuk fungsi uploadAvatar
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:astronacci_test_flutter/models/user_model.dart'; 
import 'package:astronacci_test_flutter/services/api_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService;

  ApiService get apiService => _apiService;

  AuthCubit(this._apiService) : super(AuthInitial());

  // 1. Cek Status Otentikasi saat aplikasi dimulai
  void checkAuthStatus() async {
    emit(AuthLoading());
    final token = _apiService.getTokenFromPrefs();
    if (token != null) {
      try {
        final user = await _apiService.fetchAuthenticatedUser();
        final token = _apiService.getTokenFromPrefs(); 
        emit(AuthAuthenticated(user: user, token: token!)); 
      } on DioException {
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
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    
    if (password.length < 8) {
      emit(const AuthError(
        message: 'Password harus minimal 8 karakter.',
        rawLog: 'Client-side validation failed: password too short.',
      )); 
      emit(AuthUnauthenticated()); 
      return;
    }

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      
      emit(AuthAuthenticated(user: response.user, token: response.token));
      
    } on DioException catch (e) {
      final String errorMessage = e.response?.data['message'] ?? 'Email atau password salah. Silakan coba lagi.';
      
      emit(AuthError(
        message: errorMessage,
        rawLog: e.toString(), 
      ));
      
      emit(AuthUnauthenticated()); 
      
    } catch (e) {
      emit(AuthError(
        message: 'Terjadi kesalahan tak terduga.',
        rawLog: e.toString(), 
      ));
      emit(AuthUnauthenticated()); 
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
      emit(AuthAuthenticated(user: response.user, token: response.token));
      return null; 
    } on DioException catch (e) {
      emit(AuthUnauthenticated());
      final errors = e.response?.data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.containsKey('email')) {
        return errors['email'][0]; 
      }
      return e.response?.data['message'] ?? 'Registrasi gagal, periksa data Anda.';
    } catch (e) {
      emit(AuthUnauthenticated());
      return 'Terjadi kesalahan tak terduga saat registrasi. Silakan coba lagi.';
    }
  }

  // 4. Lupa Password
  Future<String> forgotPassword(String email) async {
    try {
      await _apiService.forgotPassword(email);
      return 'Link reset password telah dikirim ke email Anda.';
    } on DioException catch (e) {
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
      // Abaikan error
    } finally {
      emit(AuthUnauthenticated());
    }
  }

  // 6. Update User Profile (Digunakan oleh EditProfileScreen)
  void updateUser(UserModel updatedUser) {
    if (state is AuthAuthenticated) {
      final existingToken = (state as AuthAuthenticated).token;
      emit(AuthAuthenticated(user: updatedUser, token: existingToken));
    }
  }
  
  // 7. POST /api/user/avatar (Upload File)
  // FIX KRITIS: Mengambil user model yang baru dari API dan memperbarui AuthState.
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      // Panggil API service untuk upload dan dapatkan UserModel yang sudah diperbarui
      final updatedUser = await _apiService.uploadAvatar(imageFile);
      
      // KRITIS: Perbarui AuthState. Ini akan memicu BlocListener 
      // di ListUserScreen untuk memanggil UserCubit.syncCurrentUserUpdate
      updateUser(updatedUser); 
      
      return null; // Sukses
      
    } on DioException catch (e) {
      return e.response?.data?['message'] ?? 'Gagal mengunggah avatar. Silakan coba lagi.';
    } catch (e) {
      return 'Terjadi kesalahan tak terduga saat upload.';
    }
  }
}
