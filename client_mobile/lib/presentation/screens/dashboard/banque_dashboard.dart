
import 'package:flutter/material.dart';
import '../../widgets/dashboard_scaffold.dart';

class BanqueDashboard extends StatelessWidget {
  final String bankName;
  final String officialId;
  final String email;
  final String phone;
  final String logoPath;

  const BanqueDashboard({
    Key? key,
    required this.bankName,
    required this.officialId,
    required this.email,
    required this.phone,
    required this.logoPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.credit_card_outlined, label: 'Loans'),
        NavItem(icon: Icons.bar_chart_outlined, label: 'Analytics'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                logoPath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(logoPath, height: 60),
                      )
                    : const Icon(Icons.account_balance, size: 60, color: Colors.green),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bankName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      Text('ID: $officialId', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Portfolio Value', style: TextStyle(fontSize: 14, color: Colors.black54)),
                            Text('242.8M', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, color: Color(0xFF2E7D32), size: 18),
                              SizedBox(width: 4),
                              Text('+12%', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Repayment Rate', style: TextStyle(fontSize: 14, color: Colors.black54)),
                            Text('94.2%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Credit', style: TextStyle(fontSize: 14, color: Colors.black54)),
                            Text('1.2k', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            Text('Farmers & Exporters', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.check_circle_outline),
                            label: Text('Approve Loan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.account_balance),
                            label: Text('Issue Credit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Text('Risk Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NPL Ratio', style: TextStyle(fontSize: 14, color: Colors.red)),
                          Text('2.4%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                          Text('Above target (+0.3%)', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('Risk Grade', style: TextStyle(fontSize: 14, color: Colors.black54)),
                              Text('AAA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('Stability', style: TextStyle(fontSize: 14, color: Colors.black54)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) => Icon(Icons.circle, size: 10, color: Color(0xFF2E7D32))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Deposits', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text('18.5M', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    SizedBox(height: 8),
                    Text('Savings Growth', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text('+8.4% YoY', style: TextStyle(fontSize: 16, color: Color(0xFF2E7D32))),
                    SizedBox(height: 8),
                    Text('Liquidity Ratio', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text('24.1%', style: TextStyle(fontSize: 16, color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('See All', style: TextStyle(fontSize: 14, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            Column(
              children: [
                _activityTile('Harvesters Co-op', 'Seasonal Equipment Loan', '-\$45,000', 'DISBURSED', Colors.red),
                _activityTile('Bio-Seed Exporters', 'Credit Line Repayment', '+\$122,800', 'SETTLED', Colors.green),
                _activityTile('Organic Farms Ltd', 'Expansion Funding', '-\$15,000', 'DISBURSED', Colors.red),
              ],
            ),
          ],
        ),

      ),
      currentIndex: 0,
      onTabSelected: (index) {},
    );
  }

  Widget _activityTile(String title, String subtitle, String amount, String status, Color amountColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.upload_file, color: Color(0xFF2E7D32)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(amount, style: TextStyle(color: amountColor, fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status, style: TextStyle(color: amountColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
