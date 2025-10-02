import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:astronacci_test_flutter/blocs/user/user_cubit.dart';
import 'package:astronacci_test_flutter/blocs/user/user_state.dart';
import 'package:astronacci_test_flutter/models/user_model.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_cubit.dart';
import 'package:astronacci_test_flutter/utils/avatar_helper.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user; 

  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  // Fungsi helper untuk membangun widget avatar
  Widget _buildAvatarWidget(BuildContext context, UserModel user, double radius) {
    // Dapatkan ApiService untuk mendapatkan base URL
    final authCubit = context.read<AuthCubit>();
    // Pastikan ApiService dan dio.options.baseUrl tersedia di AuthCubit Anda
    final baseUrl = authCubit.apiService.dio.options.baseUrl;
    
    // Gunakan helper terpusat
    final String finalAvatarUrlWithAntiCache = getAvatarUrlWithCacheBuster(
      baseUrl: baseUrl,
      user: user,
    );

    final double size = radius * 2;
    
    // PERBAIKAN KRITIS: Cek apakah URL yang dihasilkan adalah placeholder
    // Kita cek apakah URL dimulai dengan URL placeholder yang dikembalikan oleh helper.
    final bool isPlaceholder = finalAvatarUrlWithAntiCache.startsWith('https://placehold.co');

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.teal.shade200,
      child: !isPlaceholder
          ? ClipOval(
              child: Image.network(
                finalAvatarUrlWithAntiCache,
                key: ValueKey(finalAvatarUrlWithAntiCache), // Kunci unik
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(fontSize: radius * (50/70), color: Colors.teal.shade800),
                ),
              ),
            )
          : Text(
              user.name[0].toUpperCase(),
              style: TextStyle(fontSize: radius * (50/70), color: Colors.teal.shade800),
            ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengguna'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          UserModel displayUser = user;
          
          if (state is UserLoaded) {
            final updatedUser = state.users.firstWhere(
              (u) => u.id == user.id,
              orElse: () => user,
            );
            displayUser = updatedUser; 
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatarWidget(context, displayUser, 70),
                const SizedBox(height: 24),

                Text(
                  displayUser.name,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  displayUser.email,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                
                const Divider(height: 50),

                _buildInfoRow(Icons.person, 'Nama Lengkap', displayUser.name),
                _buildInfoRow(Icons.email, 'Alamat Email', displayUser.email),
              ],
            ),
          );
        },
      ),
    );
  }
}
