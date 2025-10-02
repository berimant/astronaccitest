// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/auth/auth_cubit.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/user/user_cubit.dart'; // <-- Import UserCubit baru
import 'screens/auth/login_screen.dart'; 
import 'screens/home/main_screen.dart'; 
import 'services/api_service.dart';
import 'services/dio_client.dart';

void main() async {
  // Wajib dilakukan sebelum menggunakan SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Kebutuhan API & State Management
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final DioClient dioClient = DioClient(prefs);
  final ApiService apiService = ApiService(dioClient);

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  
  const MyApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Menyediakan AuthCubit dan UserCubit untuk seluruh widget tree
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          // 1. AuthCubit: Bertanggung jawab atas Login/Register/Logout
          create: (context) => AuthCubit(apiService)..checkAuthStatus(), 
        ),
        BlocProvider(
          // 2. UserCubit: Bertanggung jawab atas Daftar Pengguna dan Pencarian
          create: (context) => UserCubit(apiService), // Tidak perlu memanggil fungsi saat inisialisasi
        ),
      ],
      child: MaterialApp(
        title: 'Skill Test App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Jika user terautentikasi, tampilkan Home
            if (state is AuthAuthenticated) {
              return const MainScreen();
            }
            // Jika belum/gagal terautentikasi, tampilkan Login
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}