import 'package:flutter/material.dart';

class FinanceurDashboard extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String fundingType;
  final String budgetRange;

  const FinanceurDashboard({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.fundingType,
    required this.budgetRange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeur Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, $fullName', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            Card(
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Email', email),
                    _infoRow('Phone', phone),
                    _infoRow('City', city),
                    _infoRow('Funding Type', fundingType),
                    _infoRow('Budget Range', budgetRange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Your dashboard features will appear here.', style: TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1B5E20),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
