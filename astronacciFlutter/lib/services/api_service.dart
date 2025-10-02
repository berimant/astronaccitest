import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart'; 
import 'package:http_parser/http_parser.dart'; 
import '../models/user_model.dart'; 
import 'dio_client.dart';
// Asumsi ini ada dan berisi kBaseUrl
import '../constants/app_constants.dart'; 

// --- Model Respons Khusus ---
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
  
  Dio get dio => _dioClient.instance; 
  
  // KRITIS: PERBAIKAN LOGIKA ASSET URL
  // Getter ini mengambil kBaseUrl dan menghapus '/api' di akhir
  // agar URL gambar menjadi 'http://...:8081/storage/...' bukan 'http://...:8081/api/storage/...'
  String get assetBaseUrl {
    String url = kBaseUrl;
    // Cek dan hapus '/api' jika ada di akhir
    if (url.toLowerCase().endsWith('/api')) {
      // Menghapus 4 karakter terakhir ('/api')
      return url.substring(0, url.length - 4);
    }
    return url;
  }

  factory ApiService.create(DioClient dioClient) {
    return ApiService(dioClient);
  }
  
  // --- Helper Baru untuk Mengoreksi Avatar URL ---
  UserModel _correctAvatarUrl(UserModel user) {
    String? rawUrl = user.avatarUrl;
    
    // Cek jika ada URL, bukan URL absolut, dan bukan URL kosong
    if (rawUrl != null && rawUrl.isNotEmpty && !rawUrl.startsWith('http')) {
      
      // Menggunakan getter assetBaseUrl yang sudah diperbaiki
      String cleanBaseUrl = assetBaseUrl; 
      
      // Pastikan Base URL tidak berakhir dengan '/' dan Raw URL tidak diawali '/'
      String path = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
      if (cleanBaseUrl.endsWith('/')) {
        cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length - 1);
      }
      
      final correctedUrl = '$cleanBaseUrl/$path';
      
      // LOGGING DIBUANG AGAR LEBIH BERSIH, Ganti dengan print jika debugging
      // print('Corrected ABSOLUTE ASSET URL: $correctedUrl'); 
      
      return UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        avatarUrl: correctedUrl, 
        createdAt: user.createdAt,
      );
    }
    return user; 
  }
  // --------------------------------------------------------
  
  // --- FIX KRITIS #1: IMPLEMENTASI FUNGSI TOKEN ---
  String? getTokenFromPrefs() { 
    return _dioClient.prefs.getString('access_token'); 
  }
  
  Future<void> _saveToken(String token) async { 
    await _dioClient.prefs.setString('access_token', token); 
  }
  
  Future<void> clearToken() async { 
    await _dioClient.prefs.remove('access_token'); 
  }
  // ---------------------------------------------------
  
  void _handleValidationError(DioException e) { 
    // Logika penanganan error 422 (Unprocessable Entity) jika ada
  }

  // 1. POST /api/register
  Future<AuthResponse> register({required String name, required String email, required String password, required String passwordConfirmation,}) async {
    try {
      final response = await _dioClient.instance.post('/register', data: {'name': name, 'email': email, 'password': password, 'password_confirmation': passwordConfirmation,});
      var user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      user = _correctAvatarUrl(user); 
      final token = response.data['access_token'] as String;
      await _saveToken(token); // KRITIS: Simpan token setelah register
      return AuthResponse(user: user, token: token);
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Registration failed.');
    }
  }

  // 2. POST /api/login
  Future<AuthResponse> login({required String email, required String password,}) async {
    try {
      final response = await _dioClient.instance.post('/login', data: {'email': email, 'password': password,});
      var user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      user = _correctAvatarUrl(user); 
      final token = response.data['access_token'] as String;
      await _saveToken(token); // KRITIS: Simpan token setelah login
      return AuthResponse(user: user, token: token);
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Login failed.');
    }
  }
  
  // 3. POST /api/logout
  Future<void> logout() async { 
    try {
      await _dioClient.instance.post('/logout');
    } finally {
      await clearToken(); // KRITIS: Hapus token setelah logout
    }
  }
  
  // 4. POST /api/forgot-password
  Future<void> forgotPassword(String email) async { 
    try {
      await _dioClient.instance.post('/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Failed to send reset link.');
    }
  }

  // 5. GET /api/user/me
  Future<UserModel> fetchAuthenticatedUser() async {
    try {
      final response = await _dioClient.instance.get('/user/me');
      var user = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
      return _correctAvatarUrl(user); 
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch authenticated user.');
    }
  }
  
  // 6. POST /api/user/profile
  Future<UserModel> updateProfile({required String name, required String email,}) async {
    try {
      // DioClient Interceptor akan menyuntikkan token di sini
      final response = await _dioClient.instance.post('/user/profile', data: {'name': name, 'email': email,});
      var user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      return _correctAvatarUrl(user); 
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Failed to update profile.');
    }
  }

  // 7. POST /api/user/avatar (Upload File)
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

      // DioClient Interceptor akan menyuntikkan token di sini
      final response = await _dioClient.instance.post('/user/avatar', data: formData);
      var user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      return _correctAvatarUrl(user); 
    } on DioException catch (e) {
      _handleValidationError(e);
      throw Exception(e.response?.data?['message'] ?? 'Failed to upload avatar.');
    }
  }

  // 8. GET /api/users
  Future<UserListResponse> fetchUsers({int page = 1, int limit = 15}) async {
    try {
      // DioClient Interceptor akan menyuntikkan token di sini
      final response = await _dioClient.instance.get('/users', queryParameters: {'page': page, 'limit': limit});
      final List<UserModel> users = (response.data['data'] as List).map((json) {
              var user = UserModel.fromJson(json as Map<String, dynamic>);
              return _correctAvatarUrl(user); 
          }).toList();
      return UserListResponse(
        users: users,
        currentPage: response.data['meta']['current_page'] as int,
        lastPage: response.data['meta']['last_page'] as int,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch users list.');
    }
  }

  // 9. GET /api/users/search?q=query
  Future<UserListResponse> searchUsers(String query) async {
    try {
      final response = await _dioClient.instance.get('/users/search', queryParameters: {'q': query});
      final List<UserModel> users = (response.data['data'] as List).map((json) {
              var user = UserModel.fromJson(json as Map<String, dynamic>);
              return _correctAvatarUrl(user); 
          }).toList();
      return UserListResponse(
        users: users,
        currentPage: response.data['meta']['current_page'] as int,
        lastPage: response.data['meta']['last_page'] as int,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to search users.');
    }
  }
  
  // 10. GET /api/users/{id}
  Future<UserModel> fetchUserDetail(int userId) async {
    try {
      final response = await _dioClient.instance.get('/users/$userId');
      var user = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
      return _correctAvatarUrl(user); 
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch user detail.');
    }
  }

  // 11. POST /api/user/password
  Future<void> changePassword({required String currentPassword, required String newPassword,}) async {
    try {
      // DioClient Interceptor akan menyuntikkan token di sini
      await _dioClient.instance.post('/user/password', data: {'current_password': currentPassword, 'password': newPassword, 'password_confirmation': newPassword,});
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data?['errors'];
        if (errors != null && errors['current_password'] != null) {
          throw Exception(errors['current_password'][0]);
        }
        _handleValidationError(e);
      }
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengganti password.');
    }
  }
}
