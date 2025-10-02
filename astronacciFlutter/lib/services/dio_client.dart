import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart'; // Asumsi path ini benar

class DioClient {
  late Dio dio;
  final SharedPreferences prefs;

  // Konstruktor menerima SharedPreferences yang sudah siap
  DioClient(this.prefs) {
    // Pastikan kBaseUrl didefinisikan (e.g., const String kBaseUrl = "http://10.0.2.2:8000/api";)
    dio = Dio(BaseOptions(
      baseUrl: kBaseUrl, 
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
      },
    ));

    // Tambahkan Interceptor untuk Token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ambil token dari SharedPreferences
        final token = prefs.getString('access_token');
        
        // Jika ada token, tambahkan ke header Authorization
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      // Penanganan Error Global 
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print('Otentikasi Gagal: Token Invalid atau Expired');
          // TODO: Implementasi logika redirect ke Login Screen jika diperlukan
        }
        return handler.next(e);
      },
    ));
  }

  // Getter untuk Dio instance
  Dio get instance => dio;
  
  // Factory constructor
  factory DioClient.create(SharedPreferences prefs) {
    return DioClient(prefs);
  }
}
