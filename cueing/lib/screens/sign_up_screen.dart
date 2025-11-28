import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'admin_screen.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'firstName': TextEditingController(),
    'lastName': TextEditingController(),
    'email': TextEditingController(),
    'phoneNumber': TextEditingController(),
    'address': TextEditingController(),
    'username': TextEditingController(),
    'password': TextEditingController(),
  };
  bool _isLoading = false;
  final _authService = AuthService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  /// Terms & Conditions dialog
  Future<void> _showTermsDialog(BuildContext context, String role) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // must choose
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'By using CUEING, you agree to:\n\n'
              '1. Sessions must be booked responsibly.\n'
              '2. Billing records must be settled promptly.\n'
              '3. Administrators reserve the right to manage queues.\n'
              '4. Misuse of the system may result in account suspension.\n\n'
              'Please read carefully before proceeding.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Decline'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You must accept the terms to continue.'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Accept'),
              onPressed: () {
                Navigator.of(context).pop();
                if (role == 'admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signUp(
      firstName: _controllers['firstName']!.text.trim(),
      lastName: _controllers['lastName']!.text.trim(),
      email: _controllers['email']!.text.trim(),
      phoneNumber: _controllers['phoneNumber']!.text.trim(),
      address: _controllers['address']!.text.trim(),
      username: _controllers['username']!.text.trim(),
      password: _controllers['password']!.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      _controllers['password']!.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );

      // Fetch current user and show Terms dialog before navigation
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        await _showTermsDialog(context, currentUser.role);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTextField(String label, String key, {bool isPassword = false, int index = 0}) {
    IconData icon;
    switch (key) {
      case 'firstName':
      case 'lastName':
        icon = Icons.person_outline;
        break;
      case 'email':
        icon = Icons.email_outlined;
        break;
      case 'phoneNumber':
        icon = Icons.phone_outlined;
        break;
      case 'address':
        icon = Icons.location_on_outlined;
        break;
      case 'username':
        icon = Icons.account_circle_outlined;
        break;
      case 'password':
        icon = Icons.lock_outline;
        break;
      default:
        icon = Icons.text_fields;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D2D2D), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D2D2D), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          floatingLabelStyle: const TextStyle(color: Color(0xFF10B981)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (key == 'email' && !value.contains('@')) return 'Please enter a valid email';
          if (key == 'username' && value.length < 3) return 'Username must be at least 3 characters';
          if (key == 'password' && value.length < 6) return 'Password must be at least 6 characters';
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF10B981)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF000000), Color(0xFF0D1F17)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SIGN UP',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField('First Name', 'firstName', index: 0),
                  _buildTextField('Last Name', 'lastName', index: 1),
                  _buildTextField('Email', 'email', index: 2),
                  _buildTextField('Phone Number', 'phoneNumber', index: 3),
                  _buildTextField('Address', 'address', index: 4),
                  _buildTextField('Username', 'username', index: 5),
                  _buildTextField('Password', 'password', isPassword: true, index: 6),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 20,
                                                    offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
