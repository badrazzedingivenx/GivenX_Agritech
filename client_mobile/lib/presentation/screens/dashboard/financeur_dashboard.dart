import 'package:flutter/material.dart';

class FinanceurDashboard extends StatefulWidget {
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
  State<FinanceurDashboard> createState() => _FinanceurDashboardState();
}

class _FinanceurDashboardState extends State<FinanceurDashboard> {
  int _selectedIndex = 0;

  // Colors exact men l-design
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color softGreen = Color(0xFFF1F8E9);
  static const Color pinkSoft = Color(0xFFFFE0E9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AgriFlow', 
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: softGreen,
            child: Icon(Icons.person_rounded, color: primaryGreen, size: 20),
          ),
        ),
        actions: const [
          Icon(Icons.notifications_none, color: Colors.grey),
          SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text('Portfolio Overview', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Welcome back, ${widget.fullName}', 
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),

            _buildTotalPortfolioCard(),

            const SizedBox(height: 20),
            _buildGreenActionCard(),

            const SizedBox(height: 30),
            _buildSectionHeader('Urgent Funding Requests'),
            const SizedBox(height: 15),

            _buildFundingItem(
              'Hydroponic Lettuce Farm', 'Silicon Valley, CA', '\$125,000', 'URGENT', 
              'assets/images/app2.png', Colors.redAccent
            ),
            _buildFundingItem(
              'Grain Silo Modernization', 'Des Moines, IA', '\$45,000', 'STANDARD', 
              'assets/images/app5.png', Colors.green
            ),

            const SizedBox(height: 25),
            const Text('Risk Distribution', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildRiskBar('Low Risk (AAA)', 0.65, '65%', Colors.green),
            const SizedBox(height: 10),
            _buildRiskBar('Moderate Risk (B)', 0.25, '25%', Colors.lightGreen),

            const SizedBox(height: 25),
            _buildYieldForecastCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- UI Helpers ---

  Widget _buildTotalPortfolioCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOTAL PORTFOLIO VALUE', 
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text('\$4.28M', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Text('↑ 12%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _smallStat('CITY', widget.city, softGreen),
                const SizedBox(width: 10),
                _smallStat('BUDGET', widget.budgetRange, pinkSoft),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _smallStat(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildGreenActionCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: accentGreen, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          const Text('Maximize Your Green Yield', 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accentGreen,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('INVEST NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFundingItem(String title, String loc, String goal, String tag, String assetPath, Color tagCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(assetPath, width: 50, height: 50, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: tagCol.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(tag, style: TextStyle(color: tagCol, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryGreen)),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRiskBar(String label, double val, String percent, Color color) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [Text(label, style: const TextStyle(fontSize: 12)), Text(percent)]),
        const SizedBox(height: 5),
        LinearProgressIndicator(value: val, color: color, backgroundColor: Colors.grey.shade200, minHeight: 8),
      ],
    );
  }

  Widget _buildYieldForecastCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: pinkSoft, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Icon(Icons.trending_up, color: Colors.pinkAccent),
          SizedBox(width: 15),
          Expanded(child: Text('Projected ROI increase of +1.4% by year-end.', 
            style: TextStyle(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('View All ›', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.eco_outlined), label: 'Projects'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Investments'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}