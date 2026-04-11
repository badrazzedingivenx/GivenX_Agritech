import 'package:flutter/material.dart';

class TransporteurDashboard extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String capacity;
  final String city;
  const TransporteurDashboard({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.capacity,
    required this.city,
  });
  @override
  State<TransporteurDashboard> createState() => _TransporteurDashboardState();
}

class _TransporteurDashboardState extends State<TransporteurDashboard> {
  int _selectedIndex = 0;

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2D7D32);
  static const Color bgColor = Color(0xFFF7FBF2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // Logo m9ad kima s-sora (Green box with leaf)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'AgriFlow',
              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.notifications_none, color: primaryGreen),
          SizedBox(width: 15),
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fleet Card
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: accentGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FLEET MANAGEMENT', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('4 Active\nTrucks', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, height: 1.1)),
                  const SizedBox(height: 20),
                  _buildChip('ON SCHEDULE', Colors.white24),
                  const SizedBox(height: 25),
                  // Buttons and Driver count alignment
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end, // Bach l-ktaba tji fo9 l-bouton
                    children: [
                      Expanded(
                        child: _buildMainBtn('VIEW\nTRIPS', Colors.white, Colors.black),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              '12 Total Drivers Online',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            _buildMainBtn('UPDATE\nSTATUS', Colors.white12, Colors.white, hasBorder: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard('OPTIMAL', '82%', 'FLEET FUEL AVG', Icons.water_drop, Colors.green, 0.8)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard('LIVE', '1,240', 'MILES TO GO', Icons.timeline, Colors.redAccent, 0.6)),
              ],
            ),
            const SizedBox(height: 20),
            // Next Pickup
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.inventory_2_outlined, color: Colors.green),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Pickup: 14:00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Sunshine Vineyards - Terminal B', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Recent Deliveries
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Deliveries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen)),
                Text('History →', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 15),
            _buildDeliveryItem('Pickup Complete - Green Valley', 'Truck #TR-402 • Organic Barley', 'DELIVERED', '09:12 AM', Colors.green, Icons.archive_outlined),
            _buildDeliveryItem('En Route - Hwy 101', 'Truck #TR-991 • Refrigerated Dairy', 'IN PROGRESS (45%)', '', Colors.green, Icons.location_on_outlined, isProgress: true),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.eco_outlined), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMainBtn(String label, Color bg, Color txt, {bool hasBorder = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        border: hasBorder ? Border.all(color: Colors.white24) : null,
      ),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStatCard(String tag, String val, String sub, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.green.shade900, size: 20),
              Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, color: color == Colors.green ? Colors.green : Colors.pink, backgroundColor: Colors.grey.shade100, minHeight: 6),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(String title, String sub, String status, String time, Color color, IconData icon, {bool isProgress = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: primaryGreen),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isProgress)
                const SizedBox(width: 60, child: LinearProgressIndicator(value: 0.45, color: Colors.green, minHeight: 4))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                  child: Text(status, style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 5),
              Text(time.isEmpty ? status : time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
} 