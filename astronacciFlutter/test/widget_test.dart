// File: test/widget_test.dart (Kode Lengkap dengan Perbaikan)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_cubit.dart'; // Asumsi path ini benar
import 'package:astronacci_test_flutter/blocs/auth/auth_state.dart'; // Asumsi path ini benar
import 'package:astronacci_test_flutter/main.dart';
import 'package:astronacci_test_flutter/services/api_service.dart';
import 'package:astronacci_test_flutter/services/dio_client.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

// 1. Buat Mock AuthCubit untuk simulasi
class MockAuthCubit extends AuthCubit {
  // Asumsi AuthCubit menerima ApiService di konstruktor
  MockAuthCubit(ApiService apiService) : super(apiService); 

  // Paksa Cubit untuk mengeluarkan AuthInitial saat pertama kali
  @override
  void checkAuthStatus() {
    emit(AuthInitial()); 
  }

  // ... (fungsi lain yang sudah ada)
}

void main() {
  late MockAuthCubit mockAuthCubit;
  late ApiService mockApiService;

  // >> FIX: UBAH SETUP MENJADI ASYNC
  setUp(() async { 
    // Memberikan nilai default agar SharedPreferences tidak crash
    SharedPreferences.setMockInitialValues({});
    
    // >> FIX: AWAIT SharedPreferences.getInstance() untuk mendapatkan instance yang siap
    final prefs = await SharedPreferences.getInstance();

    // Inisialisasi mock service dan cubit
    // DioClient.create sekarang dipanggil dengan SharedPreferences yang sudah siap (prefs)
    final dioClient = DioClient.create(prefs);
    
    // ApiService.create sekarang dipanggil dengan DioClient
    mockApiService = ApiService.create(dioClient);
    mockAuthCubit = MockAuthCubit(mockApiService);
  });

  // Uji coba pertama: Aplikasi dapat dimuat dan menampilkan Login Screen
  testWidgets('App loads and shows Login Screen initially', (WidgetTester tester) async {
    // Bungkus MyApp dengan BlocProvider agar dapat diakses
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
        ],
        // Pass parameter apiService yang dibutuhkan oleh MyApp
        child: MyApp(apiService: mockApiService), 
      ),
    );

    // Minta Flutter untuk menggambar frame, dan tunggu
    await tester.pumpAndSettle();

    // Verifikasi 1: Pastikan tidak ada error (test tidak crash)
    expect(find.byType(MyApp), findsOneWidget);

    // Verifikasi 2: Cari teks dari Login Screen untuk memastikan navigasi sudah benar
    // Login Screen memiliki AppBar dengan title 'Masuk Aplikasi'
    expect(find.text('Masuk Aplikasi'), findsOneWidget);
    
    // Verifikasi 3: Cek tombol Login
    expect(find.text('Login'), findsOneWidget);
  });
}