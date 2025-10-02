// File: lib/models/user_model.dart

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });

  // Factory method untuk membuat objek dari respons JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      // Avatar URL bisa null
      avatarUrl: json['avatar_url'] as String?, 
      createdAt: json['created_at'] as String,
    );
  }

  // Untuk debug atau logging
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, avatarUrl: $avatarUrl)';
  }
}
