

import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:agriflow/l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../models/user.dart';
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(28),
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
  bool _isLoading = false;

  void _validateAndLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _usernameController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty) {
      setState(() => _emailError = AppLocalizations.of(context)!.loginEmailRequired);
      return;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = AppLocalizations.of(context)!.loginEmailInvalid);
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = AppLocalizations.of(context)!.loginPasswordRequired);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(email, password);
      if (!mounted) return;
      setState(() => _isLoading = false);

      final userData = result['user'] as Map<String, dynamic>;
      final token = result['token'] as String?;
      if (token != null) {
        userData['token'] = token;
      }
      final user = User.fromJson(userData);

      // Save session
      await SessionService.saveSession(user);

      if (!mounted) return;
      _navigateToDashboard(user);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final errorMsg = e.toString();
      if (errorMsg.contains('401')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginInvalidCredentials)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    }
  }

  void _navigateToDashboard(User user) {
    switch (user.role) {
      case UserRole.farmer:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FarmerDashboard(
              fullName: user.fullName,
              email: user.email,
              phone: user.phone,
              city: user.city,
              farmingType: user.farmingType ?? '',
              mainProducts: user.mainProducts ?? '',
            ),
          ),
        );
      case UserRole.buyer:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UsineDashboard(
              fullName: user.fullName,
              email: user.email,
              phone: user.phone,
              city: user.city,
              companyName: user.companyName ?? '',
              productTypes: user.productTypes ?? '',
              buyerType: user.buyerType?.toJson() ?? 'restaurant',
            ),
          ),
        );
      case UserRole.transporter:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TransporteurDashboard(
              fullName: user.fullName,
              email: user.email,
              phone: user.phone,
              city: user.city,
              vehicleType: user.vehicleType ?? '',
              capacity: user.capacity ?? '',
            ),
          ),
        );
      case UserRole.bank:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BanqueDashboard(
              bankName: user.bankName ?? '',
              officialId: user.officialId ?? '',
              email: user.email,
              phone: user.phone,
              logoPath: user.logoPath ?? '',
            ),
          ),
        );
      case UserRole.admin:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginUnknownRole)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            AppLocalizations.of(context)!.loginTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            AppLocalizations.of(context)!.loginSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(height: 22),
        // Email field
        TextField(
          controller: _usernameController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.13),
            hintText: AppLocalizations.of(context)!.loginEmailHint,
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
        const SizedBox(height: 14),
        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.13),
            hintText: AppLocalizations.of(context)!.loginPasswordHint,
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
                                      Text(
                                        AppLocalizations.of(context)!.loginForgotPasswordTitle,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(context)!.loginForgotPasswordDesc,
                                        style: const TextStyle(
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
                                          hintText: AppLocalizations.of(context)!.loginEmailHint,
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
                                                _forgotEmailError = AppLocalizations.of(context)!.loginEmailRequired;
                                              } else if (!gmailRegex.hasMatch(email)) {
                                                _forgotEmailError = AppLocalizations.of(context)!.loginEmailInvalid;
                                              }
                                            });
                                            if (_forgotEmailError == null) {
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(AppLocalizations.of(context)!.loginResetLinkSent)),
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
                child: Text(
                  AppLocalizations.of(context)!.loginForgotPassword,
                  style: const TextStyle(
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
        const SizedBox(height: 6),
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
            Text(
              AppLocalizations.of(context)!.loginRememberMe,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Login button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _validateAndLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
              AppLocalizations.of(context)!.loginButton,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.loginNoAccount,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/role');
                },
                child: Text(
                  AppLocalizations.of(context)!.loginSignup,
                  style: const TextStyle(
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
