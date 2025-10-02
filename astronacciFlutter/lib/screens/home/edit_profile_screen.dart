// File: lib/screens/home/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:astronacci_test_flutter/blocs/auth/auth_cubit.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_state.dart';
import 'package:astronacci_test_flutter/services/api_service.dart'; // Pastikan path ini benar
import 'package:astronacci_test_flutter/models/user_model.dart'; // Pastikan path ini benar

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pastikan state saat ini adalah AuthAuthenticated
    final AuthAuthenticated authState = context.read<AuthCubit>().state as AuthAuthenticated;
    _nameController = TextEditingController(text: authState.user.name);
    _emailController = TextEditingController(text: authState.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- LOGIKA UPLOAD FOTO ---
  Future<void> _pickAndCropImage() async {
    // 1. Ambil Gambar dari Galeri
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 2. Lakukan Cropping
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        // Konfigurasi UI dan Cropping
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: Colors.teal,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square, // Rasio 1:1 (Kotak)
            lockAspectRatio: true, // Kunci rasio
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path); // Simpan file yang sudah di-crop
        });
        _uploadAvatar(); // Lanjutkan untuk upload
      }
    }
  }
  
  Future<void> _uploadAvatar() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);
    // Akses ApiService melalui getter publik dari AuthCubit
    final apiService = context.read<AuthCubit>().apiService; 

    try {
      final updatedUser = await apiService.uploadAvatar(_imageFile!);
      // Update state AuthCubit dengan data user baru yang berisi avatarUrl
      context.read<AuthCubit>().updateUser(updatedUser); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar berhasil diperbarui!')),
        );
        _imageFile = null; // Bersihkan file lokal sementara
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload avatar: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA UPDATE PROFIL Teks (Nama, Email) ---
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final apiService = context.read<AuthCubit>().apiService;
    
    try {
      final updatedUser = await apiService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
      );
      context.read<AuthCubit>().updateUser(updatedUser); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context); // Kembali ke ProfileScreen
      }
    } on Exception catch (e) {
      String errorMessage = 'Gagal memperbarui profil.';
      if (e.toString().contains('422')) { 
         errorMessage = 'Email sudah digunakan atau format input salah.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari state saat ini
    final AuthAuthenticated authState = context.watch<AuthCubit>().state as AuthAuthenticated;
    final UserModel user = authState.user;
    final String? avatarUrl = user.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Bagian Foto Profil ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.teal.shade200,
                      // Prioritas: 1. File lokal baru (_imageFile), 2. URL Avatar, 3. Inisial
                      child: _imageFile != null 
                        ? ClipOval(child: Image.file(_imageFile!, width: 120, height: 120, fit: BoxFit.cover))
                        : (avatarUrl != null && avatarUrl.isNotEmpty 
                            ? ClipOval(child: Image.network(
                                avatarUrl,
                                width: 120, 
                                height: 120, 
                                fit: BoxFit.cover,
                                // Fallback jika URL gagal dimuat
                                errorBuilder: (context, error, stackTrace) => Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.black)),
                              ))
                            : Text(user.name[0].toUpperCase(), style: TextStyle(fontSize: 40, color: Colors.teal.shade800))
                          ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndCropImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Input Nama ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Input Email ---
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Masukkan email yang valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // --- Tombol Simpan ---
              ElevatedButton.icon(
                icon: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Perubahan', style: const TextStyle(fontSize: 18)),
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}