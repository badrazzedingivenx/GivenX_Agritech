import 'package:flutter/material.dart';
import '../dashboard/financeur_dashboard.dart';

class FinanceurForm extends StatefulWidget {
  const FinanceurForm({super.key});

  @override
  State<FinanceurForm> createState() => _FinanceurFormState();
}

class _FinanceurFormState extends State<FinanceurForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _data = {};
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  final List<String> _fundingTypes = ['Agriculture', 'Livestock', 'Both'];
  String? _selectedFundingType;
  final List<String> _budgetRanges = ['Less than 10k', '10k–50k', '50k–100k', '>100k'];
  String? _selectedBudgetRange;

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
              'Register as Financeur',
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
              'Create your financeur account',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('Full Name', 'fullName', required: true, icon: Icons.person),
          const SizedBox(height: 18),
          _buildTextField('Phone Number', 'phone', required: true, icon: Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 18),
          _buildTextField('City', 'city', required: true, icon: Icons.location_city),
          const SizedBox(height: 18),
          _buildFundingTypeDropdown(),
          const SizedBox(height: 18),
          _buildBudgetRangeDropdown(),
          const SizedBox(height: 18),
          _buildTextField('Email', 'email', required: true, email: true, icon: Icons.email, keyboardType: TextInputType.emailAddress),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinanceurDashboard(
                        fullName: _data['fullName'] ?? '',
                        email: _data['email'] ?? '',
                        phone: _data['phone'] ?? '',
                        city: _data['city'] ?? '',
                        fundingType: _selectedFundingType ?? '',
                        budgetRange: _selectedBudgetRange ?? '',
                      ),
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

  Widget _buildFundingTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFundingType,
      items: _fundingTypes
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedFundingType = value),
      onSaved: (value) => _selectedFundingType = value,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.13),
        labelText: 'Funding Type',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.white70),
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

  Widget _buildBudgetRangeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBudgetRange,
      items: _budgetRanges
          .map((range) => DropdownMenuItem(
                value: range,
                child: Text(range, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedBudgetRange = value),
      onSaved: (value) => _selectedBudgetRange = value,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.13),
        labelText: 'Budget Range',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.monetization_on, color: Colors.white70),
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
