import 'package:flutter/material.dart';
import 'package:agriflow/l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../dashboard/transporteur_dashboard.dart';

class TransporteurForm extends StatefulWidget {
  const TransporteurForm({super.key});

  @override
  State<TransporteurForm> createState() => _TransporteurFormState();
}

class _TransporteurFormState extends State<TransporteurForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _data = {};
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  List<String> get _vehicleTypes => [
    AppLocalizations.of(context)!.registerVehicleTruck,
    AppLocalizations.of(context)!.registerVehicleVan,
    AppLocalizations.of(context)!.registerVehiclePickup,
  ];
  String? _selectedVehicleType;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              AppLocalizations.of(context)!.registerTransporteurTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              AppLocalizations.of(context)!.registerTransporteurSubtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(AppLocalizations.of(context)!.registerFullName, 'fullName', required: true, icon: Icons.person),
          const SizedBox(height: 18),
          _buildTextField(AppLocalizations.of(context)!.registerPhoneNumber, 'phone', required: true, icon: Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 18),
          _buildTextField(AppLocalizations.of(context)!.registerCity, 'city', required: true, icon: Icons.location_city),
          const SizedBox(height: 18),
          _buildVehicleTypeDropdown(),
          const SizedBox(height: 18),
          _buildTextField(AppLocalizations.of(context)!.registerCapacity, 'capacity', required: true, icon: Icons.local_shipping),
          const SizedBox(height: 18),
          _buildTextField(AppLocalizations.of(context)!.registerEmail, 'email', required: true, email: true, icon: Icons.email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 18),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.13),
              labelText: AppLocalizations.of(context)!.loginPasswordHint,
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: AppLocalizations.of(context)!.loginPasswordHint,
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
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
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.registerFieldRequired;
              if (value.length < 6) return AppLocalizations.of(context)!.registerPasswordTooWeak;
              return null;
            },
            onSaved: (value) => _data['password'] = value,
          ),
          const SizedBox(height: 18),
          TextFormField(
            obscureText: !_showConfirmPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.13),
              labelText: AppLocalizations.of(context)!.registerConfirmPassword,
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: AppLocalizations.of(context)!.registerConfirmPassword,
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
              suffixIcon: IconButton(
                icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
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
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.registerFieldRequired;
              if (value != _passwordController.text) return AppLocalizations.of(context)!.registerPasswordsDoNotMatch;
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final valid = _formKey.currentState!.validate();
                if (valid) {
                  _formKey.currentState!.save();
                  try {
                    await ApiService.registerUser({
                      'email': _data['email'] ?? '',
                      'password': _data['password'] ?? '',
                      'role': 'Transporteur',
                      'fullName': _data['fullName'] ?? '',
                      'phone': _data['phone'] ?? '',
                      'city': _data['city'] ?? '',
                      'vehicleType': _selectedVehicleType ?? '',
                      'capacity': _data['capacity'] ?? '',
                    });
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransporteurDashboard(
                          fullName: _data['fullName'] ?? '',
                          email: _data['email'] ?? '',
                          phone: _data['phone'] ?? '',
                          city: _data['city'] ?? '',
                          vehicleType: _selectedVehicleType ?? '',
                          capacity: _data['capacity'] ?? '',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registration failed: $e')),
                    );
                  }
                }
              },
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
              child: Text(
                AppLocalizations.of(context)!.loginSignup,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String key, {
    bool required = false,
    bool email = false,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.13),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        suffixIcon: suffixIcon,
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
        validator: validator ?? (value) {
          if (required && (value == null || value.isEmpty)) {
            return AppLocalizations.of(context)!.registerFieldRequired;
          }
          if (email && value != null && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
            return AppLocalizations.of(context)!.registerInvalidEmail;
          }
          return null;
        },
      onSaved: onSaved ?? (value) => _data[key] = value,
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVehicleType,
      items: _vehicleTypes
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedVehicleType = value),
      onSaved: (value) => _selectedVehicleType = value,
      validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.registerFieldRequired : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.13),
        labelText: AppLocalizations.of(context)!.registerVehicleType,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.directions_car, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
      dropdownColor: const Color(0xFF2E7D32),
    );
  }
}
