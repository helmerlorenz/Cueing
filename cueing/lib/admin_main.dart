import 'package:flutter/material.dart';
import 'screens/admin_screen.dart';

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
      home: const AdminScreen(),
    );
  }
}
