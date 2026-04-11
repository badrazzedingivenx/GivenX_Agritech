

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/mock_data/mock_users.dart';
import 'dashboard/farmer_dashboard.dart';
import 'dashboard/usine_dashboard.dart';
import 'dashboard/transporteur_dashboard.dart';
import 'dashboard/banque_dashboard.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background image (same as role selection)
          Positioned.fill(
            child: Image.asset(
              'assets/images/app1.png',
              fit: BoxFit.cover,
            ),
          ),
          // No gradient overlay, just the image like splash screen
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 380,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: _LoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  String? _emailError;
  String? _passwordError;
  // Role selection removed

  void _validateAndLogin() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      final email = _usernameController.text.trim();
      final password = _passwordController.text;
      final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com\b');
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!gmailRegex.hasMatch(email)) {
        _emailError = 'Please enter a valid Gmail address';
      }
      if (password.isEmpty) {
        _passwordError = 'Password is required';
      }
      if (_emailError == null && _passwordError == null) {
        // Check credentials against mockUsers
        final user = mockUsers.firstWhere(
          (u) => u['email'] == email && u['password'] == password,
          orElse: () => {},
        );
        if (user.isNotEmpty) {
          final role = user['role'];
          if (role == 'Agriculteur') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => FarmerDashboard(
                  fullName: user['fullName'] ?? 'Farmer',
                  email: user['email'] ?? '',
                  phone: user['phone'] ?? '',
                  city: user['city'] ?? '',
                  farmingType: user['farmingType'] ?? '',
                  mainProducts: user['mainProducts'] ?? '',
                ),
              ),
            );
          } else if (role == 'Usine') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => UsineDashboard(
                  fullName: user['fullName'] ?? 'Usine',
                  email: user['email'] ?? '',
                  phone: user['phone'] ?? '',
                  city: user['city'] ?? '',
                  companyName: user['companyName'] ?? '',
                  productTypes: user['productTypes'] ?? '',
                ),
              ),
            );
          } else if (role == 'Transporteur') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => TransporteurDashboard(
                  fullName: user['fullName'] ?? 'Transporteur',
                  email: user['email'] ?? '',
                  phone: user['phone'] ?? '',
                  city: user['city'] ?? '',
                  vehicleType: user['vehicleType'] ?? '',
                  capacity: user['capacity'] ?? '',
                ),
              ),
            );
          } else if (role == 'Banque') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => BanqueDashboard(
                  bankName: user['bankName'] ?? '',
                  officialId: user['officialId'] ?? '',
                  email: user['email'] ?? '',
                  phone: user['phone'] ?? '',
                  logoPath: user['logoPath'] ?? '',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unknown role.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password.')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Welcome back please login to your account',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Email field
        TextField(
          controller: _usernameController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.13),
            hintText: 'Email',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.email, color: Colors.white70),
            errorText: _emailError,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.13),
            hintText: 'Password',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            errorText: _passwordError,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
        ),

        // Forgot Password link (right aligned)
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final TextEditingController _forgotEmailController = TextEditingController();
                      String? _forgotEmailError;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  width: 340,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.10),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Forgot Password',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Enter your email address and we\'ll send you a reset link.',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      TextField(
                                        controller: _forgotEmailController,
                                        keyboardType: TextInputType.emailAddress,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.13),
                                          hintText: 'Email',
                                          hintStyle: const TextStyle(color: Colors.white70),
                                          prefixIcon: const Icon(Icons.email, color: Colors.white70),
                                          errorText: _forgotEmailError,
                                          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final email = _forgotEmailController.text.trim();
                                            final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com\b');
                                            setState(() {
                                              _forgotEmailError = null;
                                              if (email.isEmpty) {
                                                _forgotEmailError = 'Email is required';
                                              } else if (!gmailRegex.hasMatch(email)) {
                                                _forgotEmailError = 'Please enter a valid Gmail address';
                                              }
                                            });
                                            if (_forgotEmailError == null) {
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('If this email exists, a reset link has been sent. (demo only)')),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            backgroundColor: const Color(0xFF2E7D32),
                                            foregroundColor: Colors.white,
                                            elevation: 8,
                                            shadowColor: const Color(0xFF2E7D32).withOpacity(0.22),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          child: const Text('Send Reset Link'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF43EA7A),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Role dropdown removed
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (val) {
                setState(() {
                  _rememberMe = val ?? false;
                });
              },
              activeColor: const Color(0xFF2E7D32),
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            const Text(
              'Remember me',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Login button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _validateAndLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF2E7D32).withOpacity(0.22),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/role');
                },
                child: const Text(
                  'Signup',
                  style: TextStyle(
                    color: Color(0xFF43EA7A),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
