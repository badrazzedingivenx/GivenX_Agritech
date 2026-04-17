import 'package:flutter/material.dart';
import 'package:agriflow/l10n/app_localizations.dart';
import '../dashboard/usine_dashboard.dart';

class UsineForm extends StatefulWidget {
  const UsineForm({super.key});

  @override
  State<UsineForm> createState() => _UsineFormState();
}

class _UsineFormState extends State<UsineForm> {
    List<String> get _productTypeOptions => [
      AppLocalizations.of(context)!.registerProductFruits,
      AppLocalizations.of(context)!.registerProductVegetables,
      AppLocalizations.of(context)!.registerProductCereals,
      AppLocalizations.of(context)!.registerProductLegumes,
      AppLocalizations.of(context)!.registerProductDairy,
      AppLocalizations.of(context)!.registerProductMeat,
      AppLocalizations.of(context)!.registerProductProcessed,
      AppLocalizations.of(context)!.registerProductOrganic,
      AppLocalizations.of(context)!.registerProductFeed,
      AppLocalizations.of(context)!.registerProductOther,
    ];
    String? _selectedProductType;

    Widget _buildProductTypeDropdown() {
      return DropdownButtonFormField<String>(
        value: _selectedProductType,
        items: _productTypeOptions
            .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: const TextStyle(color: Colors.white)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedProductType = value;
          });
        },
        onSaved: (value) => _data['productTypes'] = value,
        validator: (value) {
          if (value == null || value.isEmpty) return AppLocalizations.of(context)!.registerFieldRequired;
          return null;
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.13),
          labelText: AppLocalizations.of(context)!.registerProductTypes,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.category, color: Colors.white70),
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
        dropdownColor: const Color(0xFF2E7D32),
        style: const TextStyle(color: Colors.white),
      );
    }
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _data = {};
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                AppLocalizations.of(context)!.registerUsineTitle,
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
                AppLocalizations.of(context)!.registerUsineSubtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              label: AppLocalizations.of(context)!.registerFullName,
              keyName: 'fullName',
              required: true,
              icon: Icons.person,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              label: AppLocalizations.of(context)!.registerPhoneNumber,
              keyName: 'phone',
              required: true,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              label: AppLocalizations.of(context)!.registerCity,
              keyName: 'city',
              required: true,
              icon: Icons.location_city,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              label: AppLocalizations.of(context)!.registerCompanyName,
              keyName: 'companyName',
              required: true,
              icon: Icons.business,
            ),
            const SizedBox(height: 18),
            _buildProductTypeDropdown(),
            const SizedBox(height: 18),
            _buildTextField(
              label: AppLocalizations.of(context)!.registerEmail,
              keyName: 'email',
              required: true,
              email: true,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
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
            const SizedBox(height: 8),
            // ...
            const SizedBox(height: 18),
            TextFormField(
              obscureText: !_showConfirmPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.13),
                labelText: AppLocalizations.of(context)!.registerConfirmPassword,
                labelStyle: const TextStyle(color: Colors.white70),
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
            // ...
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
                        builder: (context) => UsineDashboard(
                          fullName: _data['fullName'] ?? '',
                          phone: _data['phone'] ?? '',
                          city: _data['city'] ?? '',
                          companyName: _data['companyName'] ?? '',
                          productTypes: _data['productTypes'] ?? '',
                          email: _data['email'] ?? '',
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
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String keyName,
    bool required = false,
    bool email = false,
    IconData? icon,
    TextInputType? keyboardType,
    String? helper,
    String? why,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          obscureText: false,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.13),
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: helper,
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
            helperText: helper,
            helperStyle: const TextStyle(color: Colors.white54),
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
            if (required && (value == null || value.isEmpty)) {
              return AppLocalizations.of(context)!.registerFieldRequired;
            }
            if (email && value != null && !RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,4}$').hasMatch(value)) {
              return AppLocalizations.of(context)!.registerInvalidEmail;
            }
            return null;
          },
          onSaved: (value) => _data[keyName] = value,
        ),
        if (why != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 2),
            child: Text(why, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
      ],
    );
  }
}
