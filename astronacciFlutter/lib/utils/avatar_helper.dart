import 'package:astronacci_test_flutter/models/user_model.dart';

// Fungsi untuk membersihkan URL, memastikan tidak ada double slash.
String _cleanUrl(String url) {
  // Menghapus slash ganda dan slash di akhir string
  String cleaned = url.replaceAll(RegExp(r'/+'), '/');
  if (cleaned.endsWith('/')) {
    cleaned = cleaned.substring(0, cleaned.length - 1);
  }
  return cleaned;
}

/// Menggabungkan Base URL dengan path avatar, menambahkan cache buster.
///
/// Jika user.avatarUrl sudah berupa URL absolut (http/https), baseUrl diabaikan.
String getAvatarUrlWithCacheBuster({
  required String baseUrl,
  required UserModel user,
}) {
  // 1. Cek jika avatar kosong atau null.
  if (user.avatarUrl == null || user.avatarUrl!.isEmpty) {
    // Kembalikan URL placeholder dengan inisial nama jika tidak ada avatar
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    return 'https://placehold.co/40x40/DDDDDD/606060?text=$initial';
  }

  String avatarPath = user.avatarUrl!;
  
  // =========================================================================
  // Perbaikan Cache Buster: Gunakan updatedAt, fallback ke createdAt, 
  // dan fallback terakhir ke waktu saat ini (untuk memaksa refresh).
  // =========================================================================
  final int cacheBuster = user.updatedAt?.millisecondsSinceEpoch ?? 
                          user.createdAt?.millisecondsSinceEpoch ?? 
                          DateTime.now().millisecondsSinceEpoch; // Fallback ke waktu saat ini

  // =========================================================================
  // FIX KRITIS 1: Cek apakah path sudah merupakan URL absolut (Mengatasi double URL).
  // =========================================================================
  if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
    // Hapus query string lama jika ada (untuk membersihkan)
    final cleanPath = avatarPath.split('?').first;
    // Tambahkan cache buster yang baru
    return '$cleanPath?v=$cacheBuster';
  }

  // =========================================================================
  // LOGIKA PATH RELATIF (Hanya dijalankan jika bukan URL absolut)
  // =========================================================================

  // 2. Bersihkan Base URL (hilangkan slash di akhir)
  final cleanedBaseUrl = _cleanUrl(baseUrl);
  
  // 3. Proses path relatif: Hapus slash di awal jika ada, untuk menghindari double slash.
  if (avatarPath.startsWith('/')) {
    avatarPath = avatarPath.substring(1);
  }
  
  // Asumsi Laravel: Jika path hanya berupa nama file, tambahkan path standar.
  if (!avatarPath.startsWith('storage/avatars/') && !avatarPath.startsWith('storage/')) {
    avatarPath = 'storage/avatars/$avatarPath';
  }

  // 4. Buat URL final dengan Anti-Cache
  return '$cleanedBaseUrl/$avatarPath?v=$cacheBuster';
}
