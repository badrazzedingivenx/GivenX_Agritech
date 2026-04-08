import 'dart:ui';
import 'package:flutter/material.dart';
import 'register/fermer_form.dart';
import 'register/usine_form.dart';
import 'register/transporteur_form.dart';
import 'register/financeur_form.dart';

class RegisterScreen extends StatelessWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Widget form;
    // Map English UI label to French role for form selection
    String mappedRole = role;
    if (role == 'Farmer') mappedRole = 'Agriculteur';
    else if (role == 'Factory/Exporter') mappedRole = 'Usine / Exportateur';
    else if (role == 'Transporter') mappedRole = 'Transporteur';
    else if (role == 'Financer') mappedRole = 'Financeur';

    switch (mappedRole) {
      case 'Agriculteur':
        form = const FermerForm();
        break;
      case 'Usine / Exportateur':
        form = const UsineForm();
        break;
      case 'Transporteur':
        form = const TransporteurForm();
        break;
      case 'Financeur':
        form = const FinanceurForm();
        break;
      default:
        form = const Center(child: Text('Unknown role'));
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background image (same as login)
          Positioned.fill(
            child: Image.asset(
              'assets/images/app1.png',
              fit: BoxFit.cover,
            ),
          ),
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
                  child: SingleChildScrollView(child: form),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

