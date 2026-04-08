import 'package:flutter/material.dart';

class FarmerDashboard extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String farmingType;
  final String mainProducts;

  const FarmerDashboard({
    Key? key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.farmingType,
    required this.mainProducts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome Farmer $fullName'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name: $fullName', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('City: $city', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Farming Type: $farmingType', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Main Products: $mainProducts', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            const Text('This is your farmer dashboard.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
