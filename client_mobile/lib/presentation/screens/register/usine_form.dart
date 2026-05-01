import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/register_viewmodel.dart';
import '../dashboard/usine_dashboard.dart';

class UsineForm extends StatefulWidget {
  final String buyerType; // 'restaurant' or 'industry'
  const UsineForm({super.key, this.buyerType = 'restaurant'});

  @override
  State<UsineForm> createState() => _UsineFormState();
}

class _UsineFormState extends State<UsineForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _data = {};
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // --- Restaurant-specific options ---
  final List<String> _cuisineTypeOptions = [
    'Moroccan',
    'Mediterranean',
    'Fast Food',
    'International',
    'Pastry & Bakery',
    'Other',
  ];
  String? _selectedCuisineType;

  final List<String> _dailyOrderVolumeOptions = ['Small', 'Medium'];
  String? _selectedDailyOrderVolume;

  // --- Industry-specific options ---
  final List<String> _industryTypeOptions = [
    'Food Processing',
    'Canning & Packaging',
    'Dairy Processing',
    'Grain Milling',
    'Beverage Production',
    'Animal Feed Production',
    'Other',
  ];
  String? _selectedIndustryType;

  bool get _isRestaurant => widget.buyerType == 'restaurant';

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    required FormFieldSetter<String> onSaved,
    required IconData icon,
    bool required = true,
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
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.13),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
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
            Center(
              child: Text(
                widget.buyerType == 'industry'
                    ? 'Register as Industry'
                    : 'Register as Restaurant',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                widget.buyerType == 'industry'
                    ? 'Create your industry buyer account'
                    : 'Create your restaurant buyer account',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Phone Number',
              keyName: 'phone',
              required: true,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'City',
              keyName: 'city',
              required: true,
              icon: Icons.location_city,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: _isRestaurant ? 'Restaurant Name' : 'Factory Name',
              keyName: 'companyName',
              required: true,
              icon: Icons.business,
            ),
            const SizedBox(height: 12),
            // Role-specific fields
            if (_isRestaurant) ..._buildRestaurantFields()
            else ..._buildIndustryFields(),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Email',
              keyName: 'email',
              required: true,
              email: true,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.13),
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
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
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
            const SizedBox(height: 8),
            // ...
            const SizedBox(height: 12),
            TextFormField(
              obscureText: !_showConfirmPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.13),
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
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
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
            // ...
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final valid = _formKey.currentState!.validate();
                  if (valid) {
                    _formKey.currentState!.save();
                      final Map<String, dynamic> userData = {
                        'email': _data['email'] ?? '',
                        'password': _data['password'] ?? '',
                        'role': 'Buyer',
                        'buyerType': widget.buyerType,
                        'fullName': _data['fullName'] ?? '',
                        'phone': _data['phone'] ?? '',
                        'city': _data['city'] ?? '',
                        'companyName': _data['companyName'] ?? '',
                      };
                      if (_isRestaurant) {
                        userData['cuisineType'] = _data['cuisineType'] ?? '';
                        userData['dailyOrderVolume'] = _data['dailyOrderVolume'] ?? '';
                      } else {
                        userData['industryType'] = _data['industryType'] ?? '';
                        userData['certification'] = _data['certification'] ?? '';
                      }
                      final vm = context.read<RegisterViewModel>();
                      final user = await vm.register(userData);
                      if (!mounted) return;
                      if (user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UsineDashboard(
                              fullName: _data['fullName'] ?? '',
                              phone: _data['phone'] ?? '',
                              city: _data['city'] ?? '',
                              companyName: _data['companyName'] ?? '',
                              productTypes: '',
                              email: _data['email'] ?? '',
                              buyerType: widget.buyerType,
                              userId: user.id,
                            ),
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
                  shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.22),
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

  List<Widget> _buildRestaurantFields() {
    return [
      _buildDropdown(
        label: 'Cuisine Type',
        items: _cuisineTypeOptions,
        value: _selectedCuisineType,
        onChanged: (v) => setState(() => _selectedCuisineType = v),
        onSaved: (v) => _data['cuisineType'] = v,
        icon: Icons.restaurant_menu,
      ),
      const SizedBox(height: 12),
      _buildDropdown(
        label: 'Daily Order Volume',
        items: _dailyOrderVolumeOptions,
        value: _selectedDailyOrderVolume,
        onChanged: (v) => setState(() => _selectedDailyOrderVolume = v),
        onSaved: (v) => _data['dailyOrderVolume'] = v,
        icon: Icons.shopping_basket,
      ),
    ];
  }

  List<Widget> _buildIndustryFields() {
    return [
      _buildDropdown(
        label: 'Industry Type',
        items: _industryTypeOptions,
        value: _selectedIndustryType,
        onChanged: (v) => setState(() => _selectedIndustryType = v),
        onSaved: (v) => _data['industryType'] = v,
        icon: Icons.factory,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        label: 'Certification',
        keyName: 'certification',
        icon: Icons.verified,
        helper: 'e.g., ISO 22000, HACCP',
      ),
    ];
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
            fillColor: Colors.white.withValues(alpha: 0.13),
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
            hintText: helper,
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 20) : null,
            helperText: helper,
            helperStyle: const TextStyle(color: Colors.white54),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Required';
            }
            if (email && value != null && !RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,4}$').hasMatch(value)) {
              return 'Invalid email';
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
