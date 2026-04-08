
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../data/mock_data/mock_users.dart';
import '../dashboard/farmer_dashboard.dart';

class FermerForm extends StatefulWidget {
  const FermerForm({super.key});

  @override
  State<FermerForm> createState() => _FermerFormState();
}

class _FermerFormState extends State<FermerForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _data = {};
  final List<String> _farmingTypes = ['Agriculture', 'Livestock', 'Both'];
  String? _selectedFarmingType;
  final List<String> _mainProducts = [];
  final List<String> _productOptions = [
    'Maize', 'Wheat', 'Rice', 'Cattle', 'Goats', 'Sheep', 'Vegetables', 'Fruits', 'Other'
  ];
  final TextEditingController _mainProductsController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _mainProductsError = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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
              'Register as Farmer',
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
              'Create your farmer account',
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
          _buildFarmingTypeDropdown(),
          const SizedBox(height: 18),
          _buildMainProductsField(),
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
                setState(() {
                  _mainProductsError = _mainProducts.isEmpty;
                });
                if (valid && !_mainProductsError) {
                  _formKey.currentState!.save();
                  // Add new user to mockUsers
                  mockUsers.add({
                    'email': _data['email'] ?? '',
                    'password': _data['password'] ?? '',
                    'role': 'Agriculteur',
                    'fullName': _data['fullName'] ?? '',
                    'phone': _data['phone'] ?? '',
                    'city': _data['city'] ?? '',
                    'farmingType': _data['farmingType'] ?? '',
                    'mainProducts': _mainProducts.join(', '),
                  });
                  // Navigate to FarmerDashboard and pass user info
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmerDashboard(
                        fullName: _data['fullName'] ?? '',
                        email: _data['email'] ?? '',
                        phone: _data['phone'] ?? '',
                        city: _data['city'] ?? '',
                        farmingType: _data['farmingType'] ?? '',
                        mainProducts: _mainProducts.join(', '),
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
        if (email && value != null && !RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,4}$').hasMatch(value)) {
          return 'Invalid email';
        }
        return null;
      },
      onSaved: onSaved ?? (value) => _data[key] = value,
    );
  }

  Widget _buildFarmingTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFarmingType,
      items: _farmingTypes
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedFarmingType = value),
      onSaved: (value) => _data['farmingType'] = value,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.13),
        labelText: 'Type of Farming',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.agriculture, color: Colors.white70),
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

  Widget _buildMainProductsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Main Products', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _productOptions.map((product) {
            final selected = _mainProducts.contains(product);
            return FilterChip(
              label: Text(product, style: TextStyle(color: selected ? Colors.white : Colors.white70)),
              selected: selected,
              selectedColor: const Color(0xFF2E7D32),
              backgroundColor: const Color(0xFF2E7D32),
              checkmarkColor: Colors.white,
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    _mainProducts.add(product);
                  } else {
                    _mainProducts.remove(product);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        if (_mainProductsError)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 2),
            child: Text('Select at least one product', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
      ],
    );
  }
}
