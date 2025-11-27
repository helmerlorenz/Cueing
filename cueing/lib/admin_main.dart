import 'package:flutter/material.dart';
import 'screens/admin_screen.dart';
import 'screens/home_screen.dart';   // normal user home
import 'services/auth_service.dart'; // User class is defined here

void main() {
  runApp(const AdminControlApp());
}

class AdminControlApp extends StatelessWidget {
  const AdminControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF10B981),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const RoleGate(),   // ✅ gate decides admin vs user
    );
  }
}

class RoleGate extends StatefulWidget {
  const RoleGate({super.key});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  User? _user;   // ✅ User comes from auth_service.dart
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    // ✅ role check
    if (_user!.role.toLowerCase() == 'admin') {
      return const AdminScreen();   // admin flow with billing tab
    } else {
      return const HomeScreen();    // normal user flow
    }
  }
}
