  import 'dart:convert';
  import 'dart:async';
  import 'package:flutter/foundation.dart' show debugPrint;
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:crypto/crypto.dart';
  import 'package:firebase_core/firebase_core.dart' show Firebase;
  import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
  import 'package:cloud_firestore/cloud_firestore.dart';

  class User {
    final String firstName;
    final String lastName;
    final String email;
    final String phoneNumber;
    final String address;
    final String username;
    final String passwordHash; // empty for Firebase-backed accounts
    final String role; // 👈 new field

    User({
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.phoneNumber,
      required this.address,
      required this.username,
      required this.passwordHash,
      required this.role,
    });

    Map<String, dynamic> toJson() => {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phoneNumber,
          'address': address,
          'username': username,
          'passwordHash': passwordHash,
          'role': role,
        };

    factory User.fromJson(Map<String, dynamic> json) => User(
          firstName: json['firstName'] ?? '',
          lastName: json['lastName'] ?? '',
          email: json['email'] ?? '',
          phoneNumber: json['phoneNumber'] ?? '',
          address: json['address'] ?? '',
          username: json['username'] ?? json['email'] ?? 'unknown',
          passwordHash: json['passwordHash'] ?? '',
          role: json['role'] ?? 'user',
        );
  }

  class AuthService {
    static final AuthService _instance = AuthService._internal();
    factory AuthService() => _instance;

    final bool _useFirebase;
    final fb_auth.FirebaseAuth? _fbAuth;
    final FirebaseFirestore? _firestore;

    static const String _usersKey = 'users_list';
    static const String _currentUserKey = 'current_user';

    AuthService._internal()
        : _useFirebase = Firebase.apps.isNotEmpty,
          _fbAuth = Firebase.apps.isNotEmpty ? fb_auth.FirebaseAuth.instance : null,
          _firestore = Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

    bool get isUsingFirebase => _useFirebase;

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
      if (_useFirebase) {
        try {
          if (username.length < 3) return {'success': false, 'message': 'Username must be at least 3 characters'};
          if (password.length < 6) return {'success': false, 'message': 'Password must be at least 6 characters'};
          if (!email.contains('@')) return {'success': false, 'message': 'Invalid email address'};

          // Ensure username uniqueness in Firestore
          final usersQuery = await _firestore!.collection('users').where('username', isEqualTo: username).limit(1).get();
          if (usersQuery.docs.isNotEmpty) return {'success': false, 'message': 'Username already exists'};

          final cred = await _fbAuth!.createUserWithEmailAndPassword(email: email, password: password);
          final uid = cred.user!.uid;

          await _firestore.collection('users').doc(uid).set({
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'phoneNumber': phoneNumber,
            'address': address,
            'username': username,
            'role': 'user', // 👈 default role
            'createdAt': FieldValue.serverTimestamp(),
          });

          return {'success': true, 'message': 'Account created successfully'};
        } on fb_auth.FirebaseAuthException catch (e) {
          return {'success': false, 'message': 'Firebase error (${e.code}): ${e.message}'};
        } catch (e) {
          return {'success': false, 'message': 'Error creating account: $e'};
        }
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          final usersJson = prefs.getString(_usersKey);
          List<User> users = [];

          if (usersJson != null) {
            final List<dynamic> decoded = jsonDecode(usersJson);
            users = decoded.map((json) => User.fromJson(json)).toList();
          }

          if (users.any((u) => u.username == username)) {
            return {'success': false, 'message': 'Username already exists'};
          }
          if (users.any((u) => u.email == email)) {
            return {'success': false, 'message': 'Email already registered'};
          }

          final newUser = User(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
            address: address,
            username: username,
            passwordHash: _hashPassword(password),
            role: 'user', // 👈 default role
          );

          users.add(newUser);
          final usersJsonString = jsonEncode(users.map((u) => u.toJson()).toList());
          await prefs.setString(_usersKey, usersJsonString);
          await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));

          return {'success': true, 'message': 'Account created successfully (local)'};
        } catch (e) {
          return {'success': false, 'message': 'Error creating account: $e'};
        }
      }
    }

    // Sign in user
    Future<Map<String, dynamic>> signIn({required String username, required String password}) async {
      if (_useFirebase) {
        try {
          String resolvedEmail = username;
          if (!username.contains('@')) {
            final q = await _firestore!.collection('users').where('username', isEqualTo: username).limit(1).get();
            if (q.docs.isNotEmpty) resolvedEmail = q.docs.first.data()['email'] ?? username;
          }
          await _fbAuth!.signInWithEmailAndPassword(email: resolvedEmail, password: password);
          return {'success': true, 'message': 'Login successful'};
        } catch (e) {
          return {'success': false, 'message': 'Invalid username or password'};
        }
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          final usersJson = prefs.getString(_usersKey);
          if (usersJson == null) return {'success': false, 'message': 'No users found. Please sign up first.'};

          final List<dynamic> decoded = jsonDecode(usersJson);
          final users = decoded.map((json) => User.fromJson(json)).toList();

          final user = users.firstWhere(
            (u) => u.username == username && u.passwordHash == _hashPassword(password),
            orElse: () => throw Exception('User not found'),
          );

          await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
          return {'success': true, 'message': 'Login successful'};
        } catch (e) {
          return {'success': false, 'message': 'Invalid username or password'};
        }
      }
    }

    // Get current logged in user (with role)
    Future<User?> getCurrentUser() async {
      if (_useFirebase) {
        try {
          final fbUser = _fbAuth!.currentUser;
          if (fbUser == null) return null;
          final doc = await _firestore!.collection('users').doc(fbUser.uid).get();
          if (!doc.exists) return null;
          final data = doc.data()!;
          return User(
            firstName: data['firstName'] ?? '',
            lastName: data['lastName'] ?? '',
            email: data['email'] ?? fbUser.email ?? '',
            phoneNumber: data['phoneNumber'] ?? '',
            address: data['address'] ?? '',
            username: data['username'] ?? data['email'] ?? '',
            passwordHash: '',
            role: data['role'] ?? 'user',
          );
        } catch (_) {
          return null;
        }
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          final userJson = prefs.getString(_currentUserKey);
          if (userJson == null) return null;
          return User.fromJson(jsonDecode(userJson));
        } catch (_) {
          return null;
        }
      }
    }

    // Sign out
    Future<void> signOut() async {
      if (_useFirebase) {
        await _fbAuth!.signOut();
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_currentUserKey);
      }
    }

    // Reset password
    Future<Map<String, dynamic>> resetPassword({
      required String email,
      required String newPassword,
    }) async {
      if (_useFirebase) {
        try {
          await _fbAuth!.sendPasswordResetEmail(email: email);
          return {
            'success': true,
            'message': 'Password reset email sent. Please check your inbox.'
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error sending reset email: $e'
          };
        }
      } else {
        // Local fallback: update stored password hash
        try {
          if (newPassword.length < 6) {
            return {
              'success': false,
              'message': 'Password must be at least 6 characters'
            };
          }

          final prefs = await SharedPreferences.getInstance();
          final usersJson = prefs.getString(_usersKey);

          if (usersJson == null) {
            return {
              'success': false,
              'message': 'No account found with this email'
            };
          }

          final List<dynamic> decoded = jsonDecode(usersJson);
          List<User> users = decoded.map((json) => User.fromJson(json)).toList();

          final userIndex = users.indexWhere((user) => user.email == email);

          if (userIndex == -1) {
            return {
              'success': false,
              'message': 'No account found with this email'
            };
          }

          final user = users[userIndex];
          users[userIndex] = User(
            firstName: user.firstName,
            lastName: user.lastName,
            email: user.email,
            phoneNumber: user.phoneNumber,
            address: user.address,
            username: user.username,
            passwordHash: _hashPassword(newPassword),
            role: user.role, // 👈 preserve role in local fallback
          );

          final usersJsonString =
              jsonEncode(users.map((u) => u.toJson()).toList());
          await prefs.setString(_usersKey, usersJsonString);

          return {
            'success': true,
            'message': 'Password reset successfully'
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error resetting password: $e'
          };
        }
      }
    }
  }