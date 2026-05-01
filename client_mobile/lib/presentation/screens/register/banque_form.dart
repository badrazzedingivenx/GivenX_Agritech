import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../viewmodels/register_viewmodel.dart';
import '../dashboard/banque_dashboard.dart';

class BanqueForm extends StatefulWidget {
  const BanqueForm({super.key});

  @override
  State<BanqueForm> createState() => _BanqueFormState();
}

class _BanqueFormState extends State<BanqueForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _data = {};
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _logoController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _uploadedLogoPath;
  Uint8List? _uploadedLogoBytes;

  final List<String> _bankTypeOptions = [
    'Commercial Bank',
    'Microfinance',
    'Cooperative',
    'Development Bank',
    'Other',
  ];
  String? _selectedBankType;



  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterViewModel>(
      create: (_) => RegisterViewModel(),
      child: Consumer<RegisterViewModel>(
        builder: (context, vm, _) => Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Register as Banque',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Create your bank account',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField('Bank Name', 'bankName', required: true, icon: Icons.account_balance),
          const SizedBox(height: 12),
          _buildTextField('City', 'city', required: true, icon: Icons.location_city),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'Bank Type',
            items: _bankTypeOptions,
            value: _selectedBankType,
            onChanged: (v) => setState(() => _selectedBankType = v),
            onSaved: (v) => _data['bankType'] = v,
            icon: Icons.account_balance_wallet,
          ),
          const SizedBox(height: 12),
          _buildTextField('Institutional Email', 'email', required: true, email: true, icon: Icons.email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTextField('Phone Number', 'phone', required: true, icon: Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildLogoUploadField(),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.13),
              labelText: 'Password',
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length < 6) return 'Password too weak';
              return null;
            },
            onSaved: (value) => _data['password'] = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            obscureText: !_showConfirmPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.13),
              labelText: 'Confirm Password',
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final valid = _formKey.currentState!.validate();
                if (valid) {
                  _formKey.currentState!.save();
                  final vm = context.read<RegisterViewModel>();
                  final user = await vm.register({
                      'email': _data['email'] ?? '',
                      'password': _data['password'] ?? '',
                      'role': 'Banque',
                      'fullName': _data['fullName'] ?? '',
                      'bankName': _data['bankName'] ?? '',
                      'phone': _data['phone'] ?? '',
                      'city': _data['city'] ?? '',
                      'bankType': _data['bankType'] ?? '',
                      'logoPath': _uploadedLogoPath ?? '',
                  });
                  if (!mounted) return;
                  if (user != null) {
                    // Save the uploaded logo as profile picture for the bank profile tab
                    if (_uploadedLogoBytes != null) {
                      final bankName = _data['bankName'] ?? '';
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        'profile_image_$bankName',
                        base64Encode(_uploadedLogoBytes!),
                      );
                    }
                    if (!mounted) return;
                    // Simulate admin validation required
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Awaiting Admin Validation'),
                        content: const Text('Your registration is pending admin approval. You will be notified once validated.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BanqueDashboard(
                                    bankName: _data['bankName'] ?? '',
                                    officialId: '',
                                    email: _data['email'] ?? '',
                                    phone: _data['phone'] ?? '',
                                    logoPath: _uploadedLogoPath ?? '',
                                  ),
                                ),
                              );
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else if (vm.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registration failed: ${vm.errorMessage}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 8,
                shadowColor: const Color(0xFF2E7D32).withOpacity(0.22),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Register',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    ),
  );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    required FormFieldSetter<String> onSaved,
    required IconData icon,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: onChanged,
      onSaved: onSaved,
      validator: isRequired
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.13),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
      dropdownColor: const Color(0xFF2E7D32),
      style: const TextStyle(color: Colors.white),
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
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 20) : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
      validator: validator ?? (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Required';
        }
        if (email && value != null && !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      onSaved: onSaved ?? (value) => _data[key] = value,
    );
  }

  Widget _buildLogoUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload Logo / Verification Documents', style: TextStyle(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _logoController,
                readOnly: true,
                style: const TextStyle(color: Colors.white70),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  hintText: 'No file selected',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.upload_file, color: Colors.white70, size: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
                validator: (value) {
                  if ((_uploadedLogoPath == null || _uploadedLogoPath!.isEmpty)) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  final bytes = kIsWeb
                      ? await pickedFile.readAsBytes()
                      : await File(pickedFile.path).readAsBytes();
                  setState(() {
                    _uploadedLogoPath = pickedFile.path;
                    _uploadedLogoBytes = bytes;
                    _logoController.text = pickedFile.name;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
      ],
    );
  }
}
