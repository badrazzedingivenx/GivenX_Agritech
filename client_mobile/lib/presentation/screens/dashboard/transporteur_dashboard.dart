
import 'package:flutter/material.dart';
import '../../widgets/dashboard_scaffold.dart';




class TransporteurDashboard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DashboardScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar is handled by DashboardScaffold
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _fleetCard(),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _statCard('OPTIMAL', '82%', 'FLEET FUEL AVG', Icons.local_gas_station, Colors.green, 0.82)),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('LIVE', '1,240', 'MILES TO GOAL', Icons.timeline, Colors.pink, 0.45)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _nextPickupCard(),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Deliveries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  Row(
                    children: [
                      Text('History', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _deliveryCard(
                    icon: Icons.inventory_2,
                    title: 'Pickup Complete - Green Valley',
                    subtitle: 'Truck #TR-402 • Organic Barley',
                    status: 'DELIVERED',
                    statusColor: Colors.green,
                    time: '09:12 AM',
                  ),
                  _deliveryCard(
                    icon: Icons.location_on,
                    title: 'En Route - Hwy 101',
                    subtitle: 'Truck #TR-991 • Refrigerated Dairy',
                    status: 'IN PROGRESS (45%)',
                    statusColor: Colors.green,
                    time: '',
                    progress: 0.45,
                  ),
                  _deliveryCard(
                    icon: Icons.location_on,
                    title: 'Dropped Off - Terminal C',
                    subtitle: 'Truck #TR-220 • Bulk Grains',
                    status: 'ARCHIVED',
                    statusColor: Colors.grey,
                    time: 'Yesterday',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      currentIndex: 0,
      onTabSelected: (index) {},
    );
  }

  Widget _fleetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FLEET MANAGEMENT', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('4 Active\nTrucks', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, height: 1.1)),
          const SizedBox(height: 18),
          Row(
            children: [
              _chip('ON SCHEDULE', Colors.white24),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                  child: const Text('12 Total Drivers Online', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _fleetBtn('VIEW TRIPS', Colors.white, Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _fleetBtn('UPDATE STATUS', Colors.white10, Colors.white, border: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _fleetBtn(String label, Color bg, Color txt, {bool border = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: border ? Border.all(color: Colors.white24) : null,
      ),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _statCard(String tag, String val, String sub, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.green.shade900, size: 22),
              Text(tag, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, color: color, backgroundColor: Colors.grey.shade100, minHeight: 6),
        ],
      ),
    );
  }

  Widget _nextPickupCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
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
                Text('Sunshine Vineyards - Terminal B', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _deliveryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required String time,
    double? progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (progress != null)
                SizedBox(
                  width: 70,
                  child: LinearProgressIndicator(value: progress, color: Colors.green, minHeight: 4),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              const SizedBox(height: 5),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}