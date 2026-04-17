import 'package:flutter/material.dart';

class UsineDashboard extends StatelessWidget {
  final String fullName;
  final String phone;
  final String city;
  final String companyName;
  final String productTypes;
  final String email;

  const UsineDashboard({
    super.key,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.companyName,
    required this.productTypes,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $fullName'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name: $fullName', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('City: $city', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Company Name: $companyName', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Product Types: $productTypes', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            const Text('This is your exporter dashboard.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
