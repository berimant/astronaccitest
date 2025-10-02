// File: lib/blocs/user/user_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:astronacci_test_flutter/models/user_model.dart'; // Ganti package
import 'package:astronacci_test_flutter/services/api_service.dart'; // Ganti package
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final ApiService _apiService;
  
  UserCubit(this._apiService) : super(UserInitial());
  
  // Ukuran halaman default untuk pagination
  static const int _limit = 15; 

  // --- 1. Ambil Daftar Pengguna (Normal Load & Pagination) ---
  void fetchUsers({bool isRefresh = false}) async {
    final currentState = state;
    
    // Jangan load jika masih dalam proses loading dan bukan refresh
    if (currentState is UserLoading && !isRefresh) return;

    try {
      int nextPage = 1;
      List<UserModel> currentUsers = [];

      if (currentState is UserLoaded) {
        // Cek jika sudah mencapai batas akhir, tidak perlu load lagi
        if (!isRefresh && currentState.hasReachedMax) return; 
        
        // Jika bukan refresh, ambil halaman berikutnya dan data lama
        if (!isRefresh) {
          nextPage = currentState.currentPage + 1;
          currentUsers = currentState.users;
        }
      }
      
      // Emit Loading hanya jika ini adalah load pertama atau refresh
      if (currentState is UserInitial || isRefresh) {
        emit(UserLoading());
      }
      
      final response = await _apiService.fetchUsers(page: nextPage, limit: _limit);
      
      // Gabungkan data lama dengan data baru
      final newUsers = List<UserModel>.from(currentUsers)..addAll(response.users);

      emit(UserLoaded(
          users: newUsers,
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.lastPage,
      ));

    } on DioException catch (e) {
      // DioException saat mengambil daftar (misal: 500 server error)
      emit(UserError(e.response?.data['message'] ?? 'Gagal memuat pengguna. Silakan coba lagi.'));
    } catch (e) {
      // Error umum lainnya
      emit(UserError('Terjadi kesalahan yang tidak terduga.'));
    }
  }

  // --- 2. Pencarian Pengguna ---
  void searchUsers(String query) async {
    // Jika query kosong, kembali ke daftar pengguna normal (refresh)
    if (query.trim().isEmpty) {
      fetchUsers(isRefresh: true);
      return;
    }
    
    // Emit loading untuk pencarian
    emit(UserLoading()); 

    try {
      final response = await _apiService.searchUsers(query);
      
      // Emit Loaded state dengan hasil pencarian. 
      // Pencarian biasanya tidak menggunakan pagination di layar yang sama.
      emit(UserLoaded(
          users: response.users,
          currentPage: 1,
          hasReachedMax: true, // Asumsikan hasil pencarian dimuat semua
          searchQuery: query,
      ));

    } on DioException catch (e) {
      emit(UserError('Gagal mencari. Silakan periksa koneksi atau coba kata kunci lain.'));
    } catch (e) {
      emit(UserError('Terjadi kesalahan saat mencari.'));
    }
  }
  
  // --- 3. Sinkronisasi Data Pengguna Saat Ini (Fix Stale State) ---
  // Dipanggil oleh BlocListener di ListUserScreen ketika AuthState berubah
  void syncCurrentUserUpdate(UserModel updatedUser) {
    final currentState = state;
    
    // Hanya lakukan sinkronisasi jika state saat ini adalah UserLoaded
    if (currentState is UserLoaded) {
      
      // Menggunakan map untuk mengganti UserModel lama dengan yang baru (immutability)
      final List<UserModel> updatedList = currentState.users.map((user) {
        // Cek apakah ID user di list sama dengan ID user yang baru di-update
        if (user.id == updatedUser.id) {
          // Ganti model lama dengan model baru dari AuthCubit
          return updatedUser; 
        }
        return user;
      }).toList();

      // Emit state baru dengan list yang sudah disinkronkan
      // Pastikan semua properti UserLoaded state dipertahankan
      emit(UserLoaded(
        users: updatedList,
        hasReachedMax: currentState.hasReachedMax,
        currentPage: currentState.currentPage,
        searchQuery: currentState.searchQuery,
      ));
    }
  }
}
