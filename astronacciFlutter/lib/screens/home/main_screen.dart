import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_cubit.dart';
import 'package:astronacci_test_flutter/blocs/auth/auth_state.dart';
import 'package:astronacci_test_flutter/screens/home/list_user_screen.dart'; // Import baru
import 'package:astronacci_test_flutter/screens/home/profile_screen.dart'; // Import baru

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ListUserScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Pastikan user sudah terautentikasi sebelum mengakses MainScreen
    final AuthState state = context.watch<AuthCubit>().state;
    if (state is! AuthAuthenticated) {
      // Ini adalah pengaman, seharusnya tidak tercapai jika alur main.dart benar
      return const Scaffold(body: Center(child: Text("Unauthorized Access")));
    }
    
    // final user = state.user; // Data user bisa diakses di ProfileScreen

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.teal.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
