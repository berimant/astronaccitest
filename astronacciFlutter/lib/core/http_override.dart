import 'dart:io';

// Class ini memastikan Dart VM mengizinkan koneksi ke sertifikat yang tidak valid
// (atau, dalam kasus Anda, koneksi HTTP non-aman di lingkungan rilis)
// Ini adalah pengaman tambahan jika Android:usesCleartextTraffic saja tidak cukup.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
    // Di sini kita juga bisa mengatur properti lain seperti timeout
    // ..connectionTimeout = const Duration(seconds: 15); // Tingkatkan timeout
  }
}
