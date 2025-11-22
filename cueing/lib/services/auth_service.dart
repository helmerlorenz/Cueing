import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class User {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final String username;
  final String passwordHash;

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.username,
    required this.passwordHash,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'username': username,
        'passwordHash': passwordHash,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phoneNumber: json['phoneNumber'],
        address: json['address'],
        username: json['username'],
        passwordHash: json['passwordHash'],
      );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _usersKey = 'users_list';
  static const String _currentUserKey = 'current_user';

  // Hash password for secure storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Sign up new user
  Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    required String username,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (username.length < 3) {
        return {'success': false, 'message': 'Username must be at least 3 characters'};
      }
      if (password.length < 6) {
        return {'success': false, 'message': 'Password must be at least 6 characters'};
      }
      if (!email.contains('@')) {
        return {'success': false, 'message': 'Invalid email address'};
      }

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      List<User> users = [];

      if (usersJson != null) {
        final List<dynamic> decoded = jsonDecode(usersJson);
        users = decoded.map((json) => User.fromJson(json)).toList();
      }

      // Check if username already exists
      if (users.any((user) => user.username == username)) {
        return {'success': false, 'message': 'Username already exists'};
      }

      // Check if email already exists
      if (users.any((user) => user.email == email)) {
        return {'success': false, 'message': 'Email already registered'};
      }

      // Create new user
      final newUser = User(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        username: username,
        passwordHash: _hashPassword(password),
      );

      users.add(newUser);

      // Save users list
      final usersJsonString = jsonEncode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_usersKey, usersJsonString);

      // Auto login after signup
      await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));

      return {'success': true, 'message': 'Account created successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error creating account: $e'};
    }
  }

  // Sign in user
  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);

      if (usersJson == null) {
        return {'success': false, 'message': 'No users found. Please sign up first.'};
      }

      final List<dynamic> decoded = jsonDecode(usersJson);
      final users = decoded.map((json) => User.fromJson(json)).toList();

      // Find user with matching username and password
      final user = users.firstWhere(
        (user) => user.username == username && user.passwordHash == _hashPassword(password),
        orElse: () => throw Exception('User not found'),
      );

      // Save current user
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));

      return {'success': true, 'message': 'Login successful'};
    } catch (e) {
      return {'success': false, 'message': 'Invalid username or password'};
    }
  }

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);

      if (userJson == null) return null;

      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 6) {
        return {'success': false, 'message': 'Password must be at least 6 characters'};
      }

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);

      if (usersJson == null) {
        return {'success': false, 'message': 'No account found with this email'};
      }

      final List<dynamic> decoded = jsonDecode(usersJson);
      List<User> users = decoded.map((json) => User.fromJson(json)).toList();

      // Find user by email
      final userIndex = users.indexWhere((user) => user.email == email);

      if (userIndex == -1) {
        return {'success': false, 'message': 'No account found with this email'};
      }

      // Update password
      final user = users[userIndex];
      users[userIndex] = User(
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        address: user.address,
        username: user.username,
        passwordHash: _hashPassword(newPassword),
      );

      // Save updated users list
      final usersJsonString = jsonEncode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_usersKey, usersJsonString);

      return {'success': true, 'message': 'Password reset successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error resetting password: $e'};
    }
  }
}