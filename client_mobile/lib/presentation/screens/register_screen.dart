import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agriflow/l10n/app_localizations.dart';
import 'register/fermer_form.dart';
import 'register/usine_form.dart';
import 'register/transporteur_form.dart';
import 'register/banque_form.dart';

class RegisterScreen extends StatelessWidget {
  final String role;
  final String? buyerType;
  const RegisterScreen({super.key, required this.role, this.buyerType});

  @override
  Widget build(BuildContext context) {
    Widget form;
    switch (role) {
      case 'roleFarmer':
        form = const FermerForm();
        break;
      case 'roleBuyer':
      case 'roleFactory':
        form = UsineForm(buyerType: buyerType ?? 'restaurant');
        break;
      case 'roleTransporter':
        form = const TransporteurForm();
        break;
      case 'roleBanque':
        form = const BanqueForm();
        break;
      default:
        form = Center(child: Text(AppLocalizations.of(context)!.registerUnknownRole));
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                    child: form,
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

