import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:astronacci_test_flutter/blocs/auth/auth_cubit.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_state.dart';
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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: Colors.teal,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square, 
            lockAspectRatio: true, 
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path);
        });
        // Panggil uploadAvatar segera setelah cropping
        _uploadAvatar(); 
      }
    }
  }
  
  // FIX KRITIS: Memanggil AuthCubit.uploadAvatar
  Future<void> _uploadAvatar() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);
    
    // GANTI: Panggil metode AuthCubit yang baru kita buat
    final errorMessage = await context.read<AuthCubit>().uploadAvatar(_imageFile!); 
    
    if (mounted) {
      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar berhasil diperbarui!')),
        );
        _imageFile = null; // Hapus file lokal setelah sukses
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload avatar: $errorMessage')),
        );
      }
    }

    setState(() => _isLoading = false);
  }


  // --- LOGIKA UPDATE PROFIL Teks (Tidak Berubah) ---
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
        Navigator.pop(context);
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
  
  // --- LOGIKA LOGOUT (Tidak Berubah) ---
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari state saat ini
    final AuthAuthenticated authState = context.watch<AuthCubit>().state as AuthAuthenticated;
    final UserModel user = authState.user;
    final String? finalAvatarUrl = user.avatarUrl; 
    
    final bool hasAvatar = finalAvatarUrl != null && finalAvatarUrl.isNotEmpty;

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
                        // Menggunakan finalAvatarUrl yang sudah dijamin absolut dari AuthCubit
                        : (hasAvatar 
                            ? ClipOval(child: Image.network(
                                finalAvatarUrl!, 
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
              
              const SizedBox(height: 20),
              
              // --- Tombol Logout ---
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.red)),
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
