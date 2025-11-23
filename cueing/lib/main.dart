import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/sign_in_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase. If Firebase is not configured for this project
  // the initialization will throw; we catch the error and proceed using local
  // prototype services. You should add your platform Firebase config (google-services.json
  // / GoogleService-Info.plist) or generate `firebase_options.dart` via the
  // FlutterFire CLI for a full integration.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Initialize the auth service which will detect Firebase and switch to
    // the Firebase-backed implementation.
    AuthService();
  } catch (e) {
    // Fall back to local prototype services if Firebase init fails.
    debugPrint('Firebase initialization failed or not configured: $e');
    AuthService();
  }

  runApp(const BookingApp());
}

class BookingApp extends StatelessWidget {
  const BookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF10B981),
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFF059669),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D2D2D), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          floatingLabelStyle: const TextStyle(color: Color(0xFF10B981)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SignInScreen(),
    );
  }
}

// Firestore security rules are managed in the Firebase Console.