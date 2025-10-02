import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart'; // Digunakan untuk upload avatar yang lebih baik
import 'package:http_parser/http_parser.dart'; // Digunakan untuk upload avatar
import '../models/user_model.dart'; 
import 'dio_client.dart';

// --- Model Respons Khusus ---

// Model untuk respons Login/Register
class AuthResponse {
  final UserModel user;
  final String token;
  const AuthResponse({required this.user, required this.token});
}

// Model untuk respons List User dengan Pagination
class UserListResponse {
  final List<UserModel> users;
  final int currentPage;
  final int lastPage;

  UserListResponse({required this.users, required this.currentPage, required this.lastPage});
}

// --- Kelas Utama API Service ---

class ApiService {
  final DioClient _dioClient;

  ApiService(this._dioClient);

  // Factory constructor untuk injeksi
  factory ApiService.create(DioClient dioClient) {
    return ApiService(dioClient);
  }

  // Fungsi untuk mendapatkan token lokal dari SharedPreferences
  String? getTokenFromPrefs() {
    return _dioClient.prefs.getString('access_token');
  }

  // Helper untuk menyimpan token setelah Login/Register
  Future<void> _saveToken(String token) async {
    await _dioClient.prefs.setString('access_token', token);
  }

  // Helper untuk menghapus token saat Logout
  Future<void> clearToken() async {
    await _dioClient.prefs.remove('access_token');
  }

  // Helper untuk parsing error validasi 422
  void _handleValidationError(DioException e) {
    if (e.response?.statusCode == 422) {
        // Coba ambil pesan dari body respons Laravel
        final errors = e.response?.data?['errors'];
        
        if (errors != null && errors is Map && errors.isNotEmpty) {
            // Ambil pesan error pertama dari field manapun
            String firstError = '';
            for (var key in errors.keys) {
                if (errors[key] is List && errors[key].isNotEmpty) {
                    firstError = errors[key][0];
                    break;
                }
            }
            if (firstError.isNotEmpty) {
                throw Exception(firstError);
            }
        }
        // Fallback ke pesan default dari Laravel (jika ada)
        throw Exception(e.response?.data?['message'] ?? 'Validation Error.');
    }
  }

  // --- 1. POST /api/register ---
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dioClient.instance.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      final token = response.data['access_token'] as String;
      
      await _saveToken(token);
      return AuthResponse(user: user, token: token);
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Registration failed.');
    }
  }

  // --- 2. POST /api/login ---
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.instance.post('/login', data: {
        'email': email,
        'password': password,
      });

      final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      final token = response.data['access_token'] as String;
      
      await _saveToken(token);
      return AuthResponse(user: user, token: token);
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Login failed.');
    }
  }
  
  // --- 3. POST /api/logout ---
  Future<void> logout() async {
    // API akan menghapus token di sisi server
    try {
      await _dioClient.instance.post('/logout'); 
    } catch (e) {
      // Abaikan error jika logout gagal (misalnya, token sudah expired di sisi server)
    }
    await clearToken(); // Selalu hapus token di sisi klien
  }
  
  // --- 4. POST /api/forgot-password ---
  Future<void> forgotPassword(String email) async {
    try {
      await _dioClient.instance.post('/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Failed to request password reset.');
    }
  }

  // --- 5. GET /api/user/me (Dibutuhkan AuthCubit.checkAuthStatus) ---
  Future<UserModel> fetchAuthenticatedUser() async {
    try {
      final response = await _dioClient.instance.get('/user/me');
      // Laravel Resource membungkus data di 'data'
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>); 
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch authenticated user.');
    }
  }
  
  // --- 6. POST /api/user/profile (Edit Profile) ---
  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await _dioClient.instance.post('/user/profile', data: {
        'name': name,
        'email': email,
      });
      // Laravel mengembalikan user yang diperbarui langsung
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Failed to update profile.');
    }
  }

  // --- 7. POST /api/user/avatar (Upload File) ---
  Future<UserModel> uploadAvatar(File imageFile) async {
    try {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      String fileName = imageFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        "avatar": await MultipartFile.fromFile(
          imageFile.path, 
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final response = await _dioClient.instance.post('/user/avatar', data: formData);

      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Failed to upload avatar.');
    }
  }

  // --- 8. GET /api/users (List User + Pagination) ---
  Future<UserListResponse> fetchUsers({int page = 1, int limit = 15}) async {
    try {
      final response = await _dioClient.instance.get('/users', 
          queryParameters: {'page': page, 'limit': limit}
      );

      final List<UserModel> users = (response.data['data'] as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Asumsi metadata pagination ada di 'meta'
      return UserListResponse(
        users: users,
        currentPage: response.data['meta']['current_page'] as int,
        lastPage: response.data['meta']['last_page'] as int,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch users list.');
    }
  }

  // --- 9. GET /api/users/search?q=query (Search User) ---
  Future<UserListResponse> searchUsers(String query) async {
    try {
      final response = await _dioClient.instance.get('/users/search', 
          queryParameters: {'q': query}
      );

      final List<UserModel> users = (response.data['data'] as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Asumsi metadata pagination ada di 'meta'
      return UserListResponse(
        users: users,
        currentPage: response.data['meta']['current_page'] as int,
        lastPage: response.data['meta']['last_page'] as int,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to search users.');
    }
  }
  
  // --- 10. GET /api/users/{id} (Detail User) ---
  Future<UserModel> fetchUserDetail(int userId) async {
    try {
      final response = await _dioClient.instance.get('/users/$userId');
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch user detail.');
    }
  }

  // --- 11. POST /api/user/password (Ganti Password) ---
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Menggunakan _dioClient.instance untuk request POST
      await _dioClient.instance.post(
        '/user/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword, // Sesuai validasi Laravel
        },
      );
      // Jika sukses, respons 200/201 tanpa body error.
    } on DioException catch (e) {
      // Penanganan Error (422) untuk validasi dari Laravel
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data?['errors'];
        // Mengambil pesan error khusus untuk password lama
        if (errors != null && errors['current_password'] != null) {
          throw Exception(errors['current_password'][0]);
        }
        // Fallback ke pesan error validasi lain
        _handleValidationError(e);
      }
      // Lempar error umum jika status lain
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengganti password.');
    }
  }
}
