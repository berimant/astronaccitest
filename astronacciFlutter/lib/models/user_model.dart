import 'package:flutter/material.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl; 
  final DateTime? updatedAt; // Penting untuk Cache Buster
  final DateTime? createdAt; // DIUBAH: Sekarang menjadi DateTime?

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl, 
    this.updatedAt,
    this.createdAt, // Diperbarui
  });

  // Helper untuk parsing string tanggal ke DateTime?
  static DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  // Factory method untuk membuat objek dari respons JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final avatarPath = json['avatar_url'] as String?;
    
    // Ambil dan parsing data updated_at & created_at
    final String? updatedAtString = json['updated_at'] as String?;
    final String? createdAtString = json['created_at'] as String?;

    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: avatarPath, 
      updatedAt: _parseDate(updatedAtString), // Menggunakan helper
      createdAt: _parseDate(createdAtString), // Menggunakan helper
    );
  }

  // Untuk debug atau logging
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, avatarUrl: $avatarUrl, updatedAt: $updatedAt, createdAt: $createdAt)';
  }
}
