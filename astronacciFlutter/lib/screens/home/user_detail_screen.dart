import 'package:flutter/material.dart';
import 'package:astronacci_test_flutter/models/user_model.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;
  
  // NOTE: Harap sesuaikan BASE_URL ini agar sama dengan BASE_URL API Anda
  final String BASE_URL = 'http://10.44.208.65:8081'; 

  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  String? _getFinalAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (avatarUrl.startsWith('http')) return avatarUrl;
    if (avatarUrl.startsWith('/')) return '$BASE_URL$avatarUrl';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String? finalAvatarUrl = _getFinalAvatarUrl(user.avatarUrl);
    final bool hasAvatar = finalAvatarUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengguna'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Avatar ---
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.teal.shade200,
              child: hasAvatar
                  ? ClipOval(
                      child: Image.network(
                        finalAvatarUrl!,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          user.name[0].toUpperCase(),
                          style: TextStyle(fontSize: 50, color: Colors.teal.shade800),
                        ),
                      ),
                    )
                  : Text(
                      user.name[0].toUpperCase(),
                      style: TextStyle(fontSize: 50, color: Colors.teal.shade800),
                    ),
            ),
            const SizedBox(height: 24),

            // --- Nama ---
            Text(
              user.name,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // --- Email ---
            Text(
              user.email,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            
            const Divider(height: 50),

            // --- Informasi Tambahan ---
            _buildInfoRow(Icons.person, 'Nama Lengkap', user.name),
            _buildInfoRow(Icons.email, 'Alamat Email', user.email),
          ],
        ),
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
}