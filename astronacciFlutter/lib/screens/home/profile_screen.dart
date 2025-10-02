import 'package:astronacci_test_flutter/screens/home/edit_profile_screen.dart';
import 'package:astronacci_test_flutter/screens/home/change_password_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_cubit.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_state.dart';
import 'package:astronacci_test_flutter/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mendapatkan data user dari AuthCubit state
    final user = (context.watch<AuthCubit>().state as AuthAuthenticated).user;
    
    // --- PERUBAHAN KRITIS: Hapus BASE_URL dan Logika Konstruksi URL ---
    // user.avatarUrl kini dijamin sudah menjadi URL absolut oleh ApiService!
    final String? finalAvatarUrl = user.avatarUrl; 
    final bool hasAvatar = finalAvatarUrl != null && finalAvatarUrl.isNotEmpty;
    // ----------------------------------------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.teal.shade200,
                // Logika tampilan avatar menggunakan finalAvatarUrl
                child: hasAvatar
                    ? ClipOval(
                        child: Image.network(
                          finalAvatarUrl!, // Langsung pakai finalAvatarUrl (yang sama dengan user.avatarUrl)
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          // Fallback jika gambar gagal dimuat
                          errorBuilder: (context, error, stackTrace) {
                             // Cetak error ke konsol jika gagal dimuat (membantu debugging)
                             print('Failed to load image from URL: $finalAvatarUrl');
                             print('Image loading error: $error');
                             return Text(
                                user.name[0].toUpperCase(),
                                style: TextStyle(fontSize: 40, color: Colors.teal.shade800),
                             );
                          },
                        ),
                      )
                    : Text(
                        user.name[0].toUpperCase(),
                        style: TextStyle(fontSize: 40, color: Colors.teal.shade800),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                user.email,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
            const Divider(height: 40),
            
            _buildProfileInfo(Icons.person, 'Nama Lengkap', user.name),
            _buildProfileInfo(Icons.email, 'Email', user.email),
            
            const SizedBox(height: 40),

            // TOMBOL 1: Edit Profil
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profil'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            
            const SizedBox(height: 16), 

            // TOMBOL 2: Ganti Password
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_reset),
              label: const Text('Ganti Password'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade600, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 24),
          const SizedBox(width: 16),
          Column(
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
        ],
      ),
    );
  }
}