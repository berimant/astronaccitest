// File: lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart'; // KRITIS: Import Dio untuk melakukan ping
import 'package:astronacci_test_flutter/blocs/auth/auth_cubit.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_state.dart';
import '/screens/auth/register_screen.dart';
import '/screens/auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // SINTAKS SUDAH DIPERBAIKI di sini:
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State untuk Koneksi API
  String _apiStatus = 'Memeriksa koneksi...';
  Color _apiColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    // PING API saat screen dimuat
    _checkApiConnection(); 
  }

  // FUNGSI PING API
  Future<void> _checkApiConnection() async {
    // Baca AuthCubit untuk mendapatkan ApiService (yang memiliki Base URL Dio)
    final authCubit = context.read<AuthCubit>();
    // KRITIS: Akses Dio melalui getter publik 'dio' di ApiService
    final baseUrl = authCubit.apiService.dio.options.baseUrl;
    // KRITIS: Target endpoint Health Check (/api/health)
    final healthUrl = baseUrl + '/health'; 

    setState(() {
      _apiStatus = 'Memeriksa koneksi ke API...';
      _apiColor = Colors.orange;
    });

    try {
      // Coba GET ke endpoint /health
      final response = await Dio().get(
        healthUrl, // Menggunakan endpoint /health
        options: Options(
          receiveTimeout: const Duration(seconds: 5), 
          sendTimeout: const Duration(seconds: 5),
        ),
      ); 
      
      if (mounted) {
        // Hanya status 200 yang dianggap sukses untuk Health Check
        if (response.statusCode == 200) {
          setState(() {
            _apiStatus = 'Koneksi API Berhasil ($healthUrl). Status 200 OK.';
            _apiColor = Colors.green;
          });
        } else {
          // Status lain (meskipun 4xx) dianggap gagal untuk health check
           setState(() {
            _apiStatus = 'GAGAL: Health check merespon status ${response.statusCode} (Harusnya 200).';
            _apiColor = Colors.red;
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String message;
        // 1. Masalah Jaringan/Timeout
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.unknown) {
          message = 'GAGAL JARINGAN: Timeout atau tidak ada koneksi internet.';
        } 
        // 2. Error 5xx (Internal Server Error)
        else if (e.response != null && e.response!.statusCode! >= 500) {
           message = 'GAGAL SERVER: Error ${e.response!.statusCode} (Masalah Internal Server).';
        } 
        // 3. Error 4xx (404 Not Found, jika rute /health belum dibuat/salah)
        else {
          message = 'GAGAL: Endpoint /health tidak valid atau error ${e.response?.statusCode ?? 'tak dikenal'}.';
        }
        
        setState(() {
          _apiStatus = '$message ($healthUrl)';
          _apiColor = Colors.red;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiStatus = 'GAGAL Total: ${e.toString()}';
          _apiColor = Colors.red;
        });
      }
    }
  }

  // WIDGET STATUS KONEKSI
  Widget _buildApiStatusWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _apiColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _apiColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            _apiColor == Colors.green ? Icons.cloud_done : Icons.cloud_off,
            color: _apiColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _apiStatus,
              style: TextStyle(color: _apiColor, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          // Ikon refresh untuk mencoba koneksi lagi
          GestureDetector(
            onTap: _checkApiConnection,
            child: Icon(Icons.refresh, color: _apiColor, size: 20),
          ),
        ],
      ),
    );
  }

  // FUNGSI UNTUK MENAMPILKAN LOG ERROR LOGIN
  void _showErrorDialog(BuildContext context, String message, String? rawLog) {
    final bool showLog = rawLog != null && (rawLog.contains('DioException') || rawLog.contains('Exception') || rawLog.contains('Client-side'));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gagal Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            
            if (showLog) ...[
              const SizedBox(height: 10),
              const Text('Detail Log (Debug):', style: TextStyle(fontSize: 14, color: Colors.red)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(rawLog!, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                ),
              ),
            ],
            if (!showLog) 
              const Text('Silakan cek kembali email dan password Anda.')
          ],
        ),
        actions: <Widget>[
          if (showLog)
            TextButton(
              child: const Text('Salin Log', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: rawLog!));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log berhasil disalin! Kirimkan ke saya.')),
                );
              },
            ),
          TextButton(
            child: const Text('Tutup'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;
      
      context.read<AuthCubit>().login(email, password);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masuk Aplikasi'),
        backgroundColor: Colors.blueGrey.shade700,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) => current is AuthError, 
        listener: (context, state) {
          if (state is AuthError && mounted) {
            _showErrorDialog(context, state.message, state.rawLog);
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Selamat Datang Kembali',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // TAMPILKAN WIDGET STATUS KONEKSI API DI SINI
                  _buildApiStatusWidget(),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final bool isLoading = state is AuthLoading;
                      // Tombol Login hanya aktif jika tidak loading DAN koneksi API hijau
                      final bool canLogin = !isLoading && _apiColor == Colors.green; 

                      return ElevatedButton(
                        onPressed: canLogin ? _login : null, // Tombol nonaktif jika loading atau API error
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _apiColor == Colors.red ? 'API Gagal, Coba Lagi' : 'Login', 
                                style: const TextStyle(fontSize: 18)
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text('Lupa Password?', style: TextStyle(color: Colors.blueGrey)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Belum punya akun? Daftar di sini', style: TextStyle(color: Colors.teal)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
