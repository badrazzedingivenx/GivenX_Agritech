import 'package:flutter/material.dart';

import '../../widgets/dashboard_scaffold.dart';
import '../products/products_page.dart';
import '../products/addproducts_page.dart';
import '../profile_farmer.dart';

class FarmerDashboard extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String farmingType;
  final String mainProducts;

  const FarmerDashboard({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.farmingType,
    required this.mainProducts,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: 0,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 12),

            Text(
              'Morning, $fullName',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Your supply chain is looking healthy today.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),

            const SizedBox(height: 24),

            /// ================= BUTTONS =================
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductPage(
                            onProductAdded: (data) {},
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ADD PRODUCT'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductsPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(
                        color: Color(0xFF2E7D32),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('VIEW ORDERS'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// ================= STATS =================
            _dashboardStatCard(
              icon: Icons.inventory_2,
              label: 'Total Products',
              value: '24',
              subLabel: '+2 this week',
              color: Colors.green.shade50,
              valueColor: Colors.green,
            ),

            const SizedBox(height: 16),

            _dashboardStatCard(
              icon: Icons.local_shipping,
              label: 'Active Orders',
              value: '8',
              subLabel: '3 pending',
              color: Colors.pink.shade50,
              valueColor: Colors.pink,
            ),

            const SizedBox(height: 16),

            _dashboardStatCard(
              icon: Icons.attach_money,
              label: 'Total Earnings',
              value: '12,480 MAD',
              subLabel: '~12%',
              color: Colors.green.shade50,
              valueColor: Colors.green,
            ),

            const SizedBox(height: 28),

            /// ================= RECENT ORDERS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all activity'),
                ),
              ],
            ),

            _recentOrderTile(
              'Organic Grocers Inc.',
              '14kg Tomatoes • #ORD-7721',
              'IN TRANSIT',
              '420.00 MAD',
            ),
            _recentOrderTile(
              'Fresh Daily Market',
              '50kg Wheat • #ORD-7719',
              'PROCESSING',
              '1,280.00 MAD',
            ),
            _recentOrderTile(
              'The Green Table',
              '8kg Microgreens • #ORD-7715',
              'COMPLETED',
              '215.00 MAD',
            ),

            const SizedBox(height: 28),

            _topSellingCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),

      /// ================= NAVIGATION =================
      onTabSelected: (index) {
        switch (index) {

          case 0:
            break;

          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductsPage(),
              ),
            );
            break;

          case 2:
            // future orders page
            break;

          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileFarmerPage(
                  fullName: fullName,
                  email: email,
                  phone: phone,
                  city: city,
                  farmingType: farmingType,
                  mainProducts: mainProducts,
                ),
              ),
            );
            break;
        }
      },
    );
  }

  // باقي functions نفسهم بلا تغيير 👇

  Widget _dashboardStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? subLabel,
    required Color color,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: valueColor, size: 28),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 16, color: Colors.black54)),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: valueColor.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: valueColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentOrderTile(
    String title,
    String subtitle,
    String status,
    String amount,
  ) {
    Color statusColor;

    switch (status) {
      case 'IN TRANSIT':
        statusColor = Colors.green;
        break;
      case 'PROCESSING':
        statusColor = Colors.orange;
        break;
      case 'COMPLETED':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.shopping_basket,
          color: Color(0xFF2E7D32),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )),
            Text(amount,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _topSellingCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/lettuce.jpg',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 120, color: Colors.grey[200]),
              ),
            ),
            const SizedBox(height: 12),
            const Text('TOP SELLING',
                style: TextStyle(fontSize: 13, color: Colors.green)),
            const SizedBox(height: 4),
            const Text('Hydroponic Basil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Yield Progress'),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.82,
                    backgroundColor: Colors.green.shade100,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('82%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}