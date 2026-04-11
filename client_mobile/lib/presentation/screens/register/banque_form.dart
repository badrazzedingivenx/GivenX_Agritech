import 'package:flutter/material.dart';
import '../dashboard/banque_dashboard.dart';

class BanqueForm extends StatefulWidget {
  const BanqueForm({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Register as Banque',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Create your bank account',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('Bank Name', 'bankName', required: true, icon: Icons.account_balance),
          const SizedBox(height: 18),
          _buildTextField('Official ID (ex: CAM-001)', 'officialId', required: true, icon: Icons.badge),
          const SizedBox(height: 18),
          _buildTextField('Institutional Email', 'email', required: true, email: true, icon: Icons.email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 18),
          _buildTextField('Phone Number', 'phone', required: true, icon: Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 18),
          _buildLogoUploadField(),
          const SizedBox(height: 18),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.13),
              labelText: 'Password',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Password',
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
              if (value == null || value.isEmpty) return 'Required';
              if (value.length < 6) return 'Password too weak';
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
              labelText: 'Confirm Password',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Confirm Password',
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
              if (value == null || value.isEmpty) return 'Required';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final valid = _formKey.currentState!.validate();
                if (valid) {
                  _formKey.currentState!.save();
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
                                  officialId: _data['officialId'] ?? '',
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
              child: const Text(
                'Register',
                style: TextStyle(
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
                  hintText: 'No file selected',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.upload_file, color: Colors.white70),
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
                // Simulate file picking
                setState(() {
                  _uploadedLogoPath = 'assets/images/bank_logo.png';
                  _logoController.text = 'bank_logo.png';
                });
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
