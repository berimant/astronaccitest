import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:astronacci_test_flutter/blocs/user/user_cubit.dart';
import 'package:astronacci_test_flutter/blocs/user/user_state.dart';
import 'package:astronacci_test_flutter/models/user_model.dart';
import 'package:astronacci_test_flutter/screens/home/user_detail_screen.dart'; // Import baru

class ListUserScreen extends StatefulWidget {
  const ListUserScreen({Key? key}) : super(key: key);

  @override
  State<ListUserScreen> createState() => _ListUserScreenState();
}

class _ListUserScreenState extends State<ListUserScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  // NOTE: Harap sesuaikan BASE_URL ini agar sama dengan BASE_URL API Anda
  final String BASE_URL = 'http://10.44.208.65:8081'; 

  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      context.read<UserCubit>().fetchUsers();
    }
  }

  void _onSearchChanged(String query) {
    context.read<UserCubit>().searchUsers(query);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Fungsi helper untuk mendapatkan URL lengkap
  Widget _buildAvatarWidget(UserModel user) {
    String? finalAvatarUrl;
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      if (user.avatarUrl!.startsWith('http')) {
        finalAvatarUrl = user.avatarUrl;
      } else if (user.avatarUrl!.startsWith('/')) {
        finalAvatarUrl = '$BASE_URL${user.avatarUrl}';
      }
    }
    
    final bool hasAvatar = finalAvatarUrl != null;

    return CircleAvatar(
      backgroundColor: Colors.teal.shade100,
      child: hasAvatar
          ? ClipOval(
              child: Image.network(
                finalAvatarUrl!,
                width: 40, 
                height: 40, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(user.name[0].toUpperCase()),
              ),
            )
          : Text(user.name[0].toUpperCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengguna'),
        backgroundColor: Colors.teal,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari pengguna...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state is UserInitial || (state is UserLoading && state is! UserLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UserError) {
            return Center(
              child: Text(state.message),
            );
          }
          if (state is UserLoaded) {
            final List<UserModel> users = state.users;
            
            if (users.isEmpty) {
              return Center(
                child: Text(
                  state.searchQuery != null && state.searchQuery!.isNotEmpty
                      ? 'Tidak ada pengguna ditemukan untuk "${state.searchQuery}"'
                      : 'Belum ada pengguna terdaftar.',
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => context.read<UserCubit>().fetchUsers(isRefresh: true),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: users.length + (state.hasReachedMax ? 0 : 1), 
                itemBuilder: (context, index) {
                  if (index >= users.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final user = users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      // Menggunakan widget avatar baru
                      leading: _buildAvatarWidget(user), 
                      
                      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.email),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      
                      // LOGIKA KRITIS: Navigasi ke Detail User
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailScreen(user: user),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}