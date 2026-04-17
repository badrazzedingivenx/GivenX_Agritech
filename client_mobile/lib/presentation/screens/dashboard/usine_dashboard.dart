import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  MAIN SHELL — controls which tab is active
// ─────────────────────────────────────────────────────────
class UsineDashboard extends StatefulWidget {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? city;
  final String? companyName;
  final String? productTypes;

  const UsineDashboard({
    super.key,
    this.fullName,
    this.email,
    this.phone,
    this.city,
    this.companyName,
    this.productTypes,
  });

  @override
  State<UsineDashboard> createState() => _UsineDashboardState();
}

class _UsineDashboardState extends State<UsineDashboard> {
  int _currentIndex = 0; // 0=Home, 1=Shipments, 2=Marketplace, 3=Profile

  static const Color primaryGreen = Color(0xFF23763D);
  static const Color bgColor = Color(0xFFF4F9F3);
  static const Color textColor = Color(0xFF1A1D1A);
  static const Color textLight = Color(0xFF757575);
  static const Color navUnselected = Color(0xFF8D9991);

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.eco_outlined, label: 'Shipments'),
    _NavItem(icon: Icons.shopping_cart_outlined, label: 'Marketplace'),
    _NavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final String displayName =
        widget.fullName?.isNotEmpty == true ? widget.fullName! : 'Alexander';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            displayName: displayName,
            primaryGreen: primaryGreen,
            textColor: textColor,
            textLight: textLight,
            onTabChange: (i) => setState(() => _currentIndex = i),
          ),
          const _ShipmentsTab(
            primaryGreen: primaryGreen,
            textColor: textColor,
            textLight: textLight,
          ),
          _MarketplaceTab(
            primaryGreen: primaryGreen,
            textColor: textColor,
            textLight: textLight,
            onNavigateToShipments: () => setState(() => _currentIndex = 1),
          ),
          _ProfileTab(
            fullName: widget.fullName,
            email: widget.email,
            phone: widget.phone,
            city: widget.city,
            companyName: widget.companyName,
            productTypes: widget.productTypes,
            primaryGreen: primaryGreen,
            textColor: textColor,
            textLight: textLight,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showCreateShipmentSheet(context),
              backgroundColor: primaryGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    String titleText;
    switch (_currentIndex) {
      case 1:
        titleText = 'My Shipments';
        break;
      case 2:
        titleText = 'Marketplace';
        break;
      case 3:
        titleText = 'My Profile';
        break;
      default:
        titleText = 'AgriFlow';
    }

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          if (_currentIndex == 0) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.eco_outlined, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Text(titleText,
              style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined,
              color: primaryGreen, size: 26),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  void _showCreateShipmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateShipmentSheet(
        primaryGreen: primaryGreen,
        textColor: textColor,
        textLight: textLight,
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 24, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length, (i) {
          final isSelected = i == _currentIndex;
          final item = _navItems[i];
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon,
                      color: isSelected ? Colors.white : navUnselected,
                      size: 22),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(item.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────
//  TAB 0 — HOME
// ─────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String displayName;
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  final Function(int)? onTabChange;

  const _HomeTab({
    required this.displayName,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EXPORTER DASHBOARD',
              style: TextStyle(
                  color: primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text('Hello, $displayName',
              style: TextStyle(
                  fontSize: 28,
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Here is the status of your global shipments today.',
              style: TextStyle(color: textLight, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChange?.call(2),
                  child: _buildActionButton(
                      'Manage\nProducts', Icons.inventory_2_outlined, false),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChange?.call(1),
                  child: _buildActionButton('Add\nShipment', Icons.add, true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatCard(
              icon: Icons.local_shipping,
              iconBgColor: const Color(0xFFDDF1E3),
              iconColor: primaryGreen,
              value: '15',
              title: 'Total Shipments',
              badge: '+2 new'),
          const SizedBox(height: 15),
          _buildStatCard(
              icon: Icons.public,
              iconBgColor: const Color(0xFFFCEAE8),
              iconColor: const Color(0xFFB52B35),
              value: '4',
              title: 'Countries Active'),
          const SizedBox(height: 20),
          const LiveNetworkCard(),
          const SizedBox(height: 24),
          _buildMarketplaceSection(),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Active Batches',
                  style: TextStyle(
                      fontSize: 18,
                      color: textColor,
                      fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: () => onTabChange?.call(1),
                child: Text('View All',
                    style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBatchItem(
            icon: Icons.inventory_2,
            title: 'Batch #EXP-915',
            subtitle: 'Destination: Rotterdam, NL',
            statusText: 'DELIVERED',
            statusBgColor: primaryGreen,
            statusTextColor: Colors.white,
          ),
          const SizedBox(height: 15),
          _buildInsightCard(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isPrimary ? primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPrimary
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : textColor, size: 20),
          const SizedBox(width: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isPrimary ? Colors.white : textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String value,
    required String title,
    String? badge,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(badge,
                      style: TextStyle(
                          color: primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                  fontSize: 32, color: textColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: textLight, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMarketplaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Global Marketplace',
                style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.w800)),
            GestureDetector(
              onTap: () => onTabChange?.call(2),
              child: Text('Explore',
                  style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => onTabChange?.call(2),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/marketplace_banner.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43EA7A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('NEW ARRIVALS',
                              style: TextStyle(
                                  color: Color(0xFF0F3628),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                        ),
                        const SizedBox(height: 8),
                        const Text('Direct Sourcing from 500+ Local Farms',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                      color: Colors.black45,
                                      blurRadius: 10,
                                      offset: Offset(0, 2))
                                ])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF4F6F4),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: const Color(0xFF5A5E5A), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: textLight, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: statusBgColor, borderRadius: BorderRadius.circular(12)),
            child: Text(statusText,
                style: TextStyle(
                    color: statusTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.bar_chart,
                size: 150, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Supply Chain Insight',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    children: [
                      TextSpan(text: 'Your export volume to '),
                      TextSpan(
                          text: 'Netherlands',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              ' has increased by 22% this quarter. Consider optimizing freight routes for better margins.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showLogisticsReport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  child: const Text('View Report',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogisticsReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.analytics_outlined,
                        color: primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Supply Chain Report',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                        Text('Q3 2026 Analysis • Netherlands',
                            style: TextStyle(
                                color: Color(0xFF757575), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _reportItem('Volume Growth', '+22.4%', Icons.trending_up,
                  Colors.green.shade700),
              _reportItem('Avg. Transit Time', '14.2 Days',
                  Icons.timer_outlined, Colors.blue.shade700),
              _reportItem('Cost Optimization', '-\$1,240/batch', Icons.savings,
                  Colors.orange.shade700),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text('Acknowledge Insights',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportItem(String title, String val, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(val,
              style: const TextStyle(
                  color: Color(0xFF1A1D1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TAB 1 — SHIPMENTS (PREMIUM REDESIGN)
// ─────────────────────────────────────────────────────────
class _ShipmentsTab extends StatefulWidget {
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  const _ShipmentsTab({
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
  });

  @override
  State<_ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends State<_ShipmentsTab> {
  String _activeFilter = 'All Shipments';
  final List<String> _filters = ['All Shipments', 'International', 'Local'];
  final Set<String> _expandedIds = {};

  final List<Map<String, dynamic>> _shipmentData = [
    {
      'id': '#EXP-915',
      'destination': 'Rotterdam, Netherlands',
      'weight': '2,450 kg',
      'date': 'Oct 24, 2026',
      'status': 'DELIVERED',
      'statusColor': const Color(0xFFE8F5E9),
      'statusText': const Color(0xFF2E7D32),
      'icon': Icons.inventory_2,
      'isInternational': true,
    },
    {
      'id': '#EXP-884',
      'destination': 'Singapore Port, SG',
      'weight': '1,820 kg',
      'date': 'Oct 29, 2026',
      'status': 'IN TRANSIT',
      'statusColor': const Color(0xFFFFF3E0),
      'statusText': const Color(0xFFEF6C00),
      'icon': Icons.local_shipping,
      'isInternational': true,
    },
    {
      'id': '#EXP-872',
      'destination': 'Hamburg, Germany',
      'weight': '3,110 kg',
      'date': 'Oct 30, 2026',
      'status': 'SHIPPED',
      'statusColor': const Color(0xFFE3F2FD),
      'statusText': const Color(0xFF1565C0),
      'icon': Icons.inventory_2,
      'isInternational': true,
    },
    {
      'id': '#LOC-442',
      'destination': 'Casablanca, Morocco',
      'weight': '4,100 kg',
      'date': 'Nov 02, 2026',
      'status': 'PROCESSING',
      'statusColor': const Color(0xFFF3E5F5),
      'statusText': const Color(0xFF7B1FA2),
      'icon': Icons.home_work,
      'isInternational': false,
    },
    {
      'id': '#LOC-398',
      'destination': 'Tangier, Morocco',
      'weight': '12,000 kg',
      'date': 'Nov 05, 2026',
      'status': 'IN TRANSIT',
      'statusColor': const Color(0xFFFFF3E0),
      'statusText': const Color(0xFFEF6C00),
      'icon': Icons.local_shipping,
      'isInternational': false,
    },
    {
      'id': '#LOC-215',
      'destination': 'Agadir, Morocco',
      'weight': '8,500 kg',
      'date': 'Nov 08, 2026',
      'status': 'DELIVERED',
      'statusColor': const Color(0xFFE8F5E9),
      'statusText': const Color(0xFF2E7D32),
      'icon': Icons.check_circle_outline,
      'isInternational': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredShipments {
    if (_activeFilter == 'All Shipments') return _shipmentData;
    if (_activeFilter == 'International') {
      return _shipmentData.where((s) => s['isInternational'] == true).toList();
    }
    if (_activeFilter == 'Local') {
      return _shipmentData.where((s) => s['isInternational'] == false).toList();
    }
    return _shipmentData;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.primaryGreen,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Active',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('124',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('+12%',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Total weight: 1.5M tons',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _smallStats(
                      'Delivered',
                      '82',
                      Icons.check_circle_outline,
                      const Color(0xFFE8F5E9),
                      const Color(0xFF2E7D32))),
              const SizedBox(width: 16),
              Expanded(
                  child: _smallStats(
                      'In Transit',
                      '42',
                      Icons.local_shipping_outlined,
                      const Color(0xFFFCE4EC),
                      const Color(0xFFC2185B))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, i) {
                      final filter = _filters[i];
                      final isSelected = filter == _activeFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = filter),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isSelected ? widget.primaryGreen : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Text(filter,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : widget.textColor,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Icon(Icons.tune, size: 18, color: widget.textColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('All Shipments',
              style: TextStyle(
                  fontSize: 18,
                  color: widget.textColor,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ..._filteredShipments.map((s) => _buildShipCard(s)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _smallStats(
      String title, String val, IconData icon, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.withValues(alpha: 0.3), size: 12),
            ],
          ),
          const SizedBox(height: 16),
          Text(val,
              style: TextStyle(
                  fontSize: 22,
                  color: widget.textColor,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: widget.textLight, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildShipCard(Map<String, dynamic> s) {
    final String id = s['id'] as String;
    final bool isExpanded = _expandedIds.contains(id);

    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedIds.remove(id);
        } else {
          _expandedIds.add(id);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s['icon'] as IconData,
                      color: widget.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s['id'] as String,
                              style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: s['statusColor'] as Color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(s['status'] as String,
                                style: TextStyle(
                                    color: s['statusText'] as Color,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(s['destination'] as String,
                          style:
                              TextStyle(color: widget.textLight, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem('Weight', s['weight'] as String),
                _infoItem('ETA', s['date'] as String),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoItem('Carrier', 'Maersk Logistics'),
                  _infoItem('Route', 'Direct Sea'),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoItem('Containers', '3 x 40ft High Cube'),
                  _infoItem('Insurance', 'Ref: INS-7729-B'),
                ],
              ),
            ],
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: widget.textLight,
                size: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: widget.textLight, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val,
            style: TextStyle(
                color: widget.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TAB 2 — MARKETPLACE REDESIGNED
// ─────────────────────────────────────────────────────────
class _MarketplaceTab extends StatefulWidget {
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  final VoidCallback? onNavigateToShipments;

  const _MarketplaceTab({
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
    this.onNavigateToShipments,
  });

  @override
  State<_MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<_MarketplaceTab> {
  String _selectedCategory = 'All';
  bool _urgentOnly = false;
  bool _organicOnly = false;
  double _maxPrice = 5000;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Stock',
    'Seeds',
    'Machines',
    'Tools',
    'Fruits',
    'Vegetables'
  ];

  final List<Map<String, dynamic>> _allProducts = [
    // --- STOCK (10) ---
    {
      'name': 'Horse',
      'origin': 'Tanger, Morocco',
      'price': '\$1,850',
      'priceValue': 1850.0,
      'category': 'Stock',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/horse.jpg',
    },
    {
      'name': 'Holstein Dairy Cow',
      'origin': 'El Jadida, Morocco',
      'price': '\$1,400',
      'priceValue': 1400.0,
      'category': 'Stock',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/dairy_cow.jpg',
    },
    {
      'name': 'Sardi Sheep (Pack of 5)',
      'origin': 'Settat, Morocco',
      'price': '\$1,200',
      'priceValue': 1200.0,
      'category': 'Stock',
      'isUrgent': true,
      'isOrganic': true,
      'image': 'assets/images/usine/sardi_sheep.jpg',
    },
    {
      'name': 'Alpine Goat',
      'origin': 'Chefchaouen, Morocco',
      'price': '\$250',
      'priceValue': 250.0,
      'category': 'Stock',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/alpine_goat.jpg',
    },
    {
      'name': 'Rhode Island Red Chickens (20)',
      'origin': 'Benslimane, Morocco',
      'price': '\$180',
      'priceValue': 180.0,
      'category': 'Stock',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/red_chickens.jpg',
    },
    {
      'name': 'Dromedary Camel (Young)',
      'origin': 'Laâyoune, Morocco',
      'price': '\$3,200',
      'priceValue': 3200.0,
      'category': 'Stock',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/dromedary_camel.jpg',
    },
    {
      'name': 'Limousin Beef Cattle',
      'origin': 'Fès, Morocco',
      'price': '\$1,650',
      'priceValue': 1650.0,
      'category': 'Stock',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/limousin_beef_cattle.jpg',
    },
    {
      'name': 'Boer Goat Buck',
      'origin': 'Taroudant, Morocco',
      'price': '\$320',
      'priceValue': 320.0,
      'category': 'Stock',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/boer_goat_buck.jpg',
    },
    {
      'name': 'Merino Ewe Lambs (10)',
      'origin': 'Ifrane, Morocco',
      'price': '\$950',
      'priceValue': 950.0,
      'category': 'Stock',
      'isUrgent': true,
      'isOrganic': true,
      'image': 'assets/images/usine/merino_ewe.jpg',
    },
    {
      'name': 'duck',
      'origin': 'Kenitra, Morocco',
      'price': '\$2,100',
      'priceValue': 2100.0,
      'category': 'Stock',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/duck.jpg',
    },
    // --- TOOLS (10) ---
    {
      'name': 'Pruning Shears',
      'origin': 'Marrakech, Morocco',
      'price': '\$25',
      'priceValue': 25.0,
      'category': 'Tools',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/shears.jpg',
    },
    {
      'name': 'Traditional Hoe (Atala)',
      'origin': 'Taza, Morocco',
      'price': '\$15',
      'priceValue': 15.0,
      'category': 'Tools',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/hoe.jpg',
    },
    {
      'name': 'Garden Spade',
      'origin': 'Tanger, Morocco',
      'price': '\$20',
      'priceValue': 20.0,
      'category': 'Tools',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/spade.jpg',
    },
    {
      'name': 'Farm Sickle (Klas)',
      'origin': 'Chefchaouen, Morocco',
      'price': '\$10',
      'priceValue': 10.0,
      'category': 'Tools',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/sickle.jpg',
    },
    {
      'name': 'Wheelbarrow (Metal)',
      'origin': 'Casablanca, Morocco',
      'price': '\$75',
      'priceValue': 75.0,
      'category': 'Tools',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/wheelbarrow.jpg',
    },
    {
      'name': 'Backpack Sprayer',
      'origin': 'El Jadida, Morocco',
      'price': '\$55',
      'priceValue': 55.0,
      'category': 'Tools',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/sprayer.jpg',
    },
    {
      'name': 'Leather Gloves',
      'origin': 'Nador, Morocco',
      'price': '\$12',
      'priceValue': 12.0,
      'category': 'Tools',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/gloves.jpg',
    },
    {
      'name': 'Garden Fork',
      'origin': 'Bouznika, Morocco',
      'price': '\$30',
      'priceValue': 30.0,
      'category': 'Tools',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/fork.jpg',
    },
    {
      'name': 'Hand Rake',
      'origin': 'Salé, Morocco',
      'price': '\$18',
      'priceValue': 18.0,
      'category': 'Tools',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/rake.jpg',
    },
    {
      'name': 'Tree Lopper',
      'origin': 'Azrou, Morocco',
      'price': '\$40',
      'priceValue': 40.0,
      'category': 'Tools',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/lopper.jpg',
    },

    // --- SEEDS (10) ---
    {
      'name': 'Durum Wheat Seeds',
      'origin': 'Meknès, Morocco',
      'price': '\$0.45/kg',
      'priceValue': 0.45,
      'category': 'Seeds',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/durum_wheat.jpg',
    },
    {
      'name': 'Hybrid Maize Seeds',
      'origin': 'Beni Mellal, Morocco',
      'price': '\$1.20/kg',
      'priceValue': 1.20,
      'category': 'Seeds',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/hybrid_maize_seeds.jpg',
    },
    {
      'name': 'Barley Seeds',
      'origin': 'Berrechid, Morocco',
      'price': '\$0.38/kg',
      'priceValue': 0.38,
      'category': 'Seeds',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/barley.jpg',
    },
    {
      'name': 'Tomato Seeds',
      'origin': 'Agadir, Morocco',
      'price': '\$15.00/pack',
      'priceValue': 15.0,
      'category': 'Seeds',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/tomato_seeds.jpg',
    },
    {
      'name': 'Coriander Seeds (9zbor)',
      'origin': 'Gharb, Morocco',
      'price': '\$5.50/kg',
      'priceValue': 5.50,
      'category': 'Seeds',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/coriander_seeds.jpg',
    },
    {
      'name': 'White Beans (L-lobya)',
      'origin': 'Doukkala, Morocco',
      'price': '\$1.30/kg',
      'priceValue': 1.30,
      'category': 'Seeds',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/white_beans.jpg',
    },
    {
      'name': 'Cumin Seeds (Kamoun)',
      'origin': 'Alnif, Morocco',
      'price': '\$22.00/kg',
      'priceValue': 22.0,
      'category': 'Seeds',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/cumin_seeds.jpg',
    },
    {
      'name': 'Chickpea Seeds',
      'origin': 'Sidi Kacem, Morocco',
      'price': '\$1.15/kg',
      'priceValue': 1.15,
      'category': 'Seeds',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/chickpeas.jpg',
    },
    {
      'name': 'Lentil Seeds',
      'origin': 'Zaer, Morocco',
      'price': '\$1.40/kg',
      'priceValue': 1.40,
      'category': 'Seeds',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/lentils.jpg',
    },
    {
      'name': 'Sunflower Seeds',
      'origin': 'Gharb, Morocco',
      'price': '\$1.05/kg',
      'priceValue': 1.05,
      'category': 'Seeds',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/sunflower_seeds.jpg',
    },

    // --- MACHINES (10) ---
    {
      'name': 'Solar Water Pump System',
      'origin': 'Ouarzazate, Morocco',
      'price': '\$1,200',
      'priceValue': 1200.0,
      'category': 'Machines',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/solar_pump.jpg',
    },
    {
      'name': 'Drip Irrigation Controller',
      'origin': 'Agadir, Morocco',
      'price': '\$450',
      'priceValue': 450.0,
      'category': 'Machines',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/irrigation_kit.jpg',
    },
    {
      'name': 'Modern Olive Oil Press',
      'origin': 'Ouazzane, Morocco',
      'price': '\$3,800',
      'priceValue': 3800.0,
      'category': 'Machines',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/olive_press.jpg',
    },
    {
      'name': 'Grain Sifter Machine',
      'origin': 'Fès, Morocco',
      'price': '\$1,100',
      'priceValue': 1100.0,
      'category': 'Machines',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/grain_sifter.jpg',
    },
    {
      'name': 'Electric Milking Machine',
      'origin': 'Kenitra, Morocco',
      'price': '\$850',
      'priceValue': 850.0,
      'category': 'Machines',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/milker.jpg',
    },
    {
      'name': 'Automatic Seeder Machine',
      'origin': 'Larache, Morocco',
      'price': '\$2,400',
      'priceValue': 2400.0,
      'category': 'Machines',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/seeder.jpg',
    },
    {
      'name': 'Digital Soil pH Tester',
      'origin': 'Rabat, Morocco',
      'price': '\$150',
      'priceValue': 150.0,
      'category': 'Machines',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/ph_tester.jpg',
    },
    {
      'name': 'Digital Egg Incubator',
      'origin': 'Fès, Morocco',
      'price': '\$320',
      'priceValue': 320.0,
      'category': 'Machines',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/egg_incubator.jpg',
    },
    {
      'name': 'Combine Harvester  ',
      'origin': 'Gharb, Morocco',
      'price': '\$85,000',
      'priceValue': 85000.0,
      'category': 'Machines',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/harvester.jpg',
    },
    {
      'name': 'Compact Utility Tractor',
      'origin': 'Casablanca, Morocco',
      'price': '\$14,500',
      'priceValue': 14500.0,
      'category': 'Machines',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/tractor.jpg',
    },

    // --- FRUITS (5) ---
    {
      'name': 'Navel Oranges',
      'origin': 'Berkane, Morocco',
      'price': '\$0.65/kg',
      'priceValue': 0.65,
      'category': 'Fruits',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/oranges.jpg',
    },
    {
      'name': 'Watermelon (Dalla7)',
      'origin': 'Zagora, Morocco',
      'price': '\$0.40/kg',
      'priceValue': 0.40,
      'category': 'Fruits',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/watermelon.jpg',
    },
    {
      'name': 'Sweet Strawberries',
      'origin': 'Larache, Morocco',
      'price': '\$2.50/kg',
      'priceValue': 2.50,
      'category': 'Fruits',
      'isUrgent': true,
      'isOrganic': true,
      'image': 'assets/images/usine/strawberries.jpg',
    },
    {
      'name': 'Red Apples',
      'origin': 'Midelt, Morocco',
      'price': '\$1.10/kg',
      'priceValue': 1.10,
      'category': 'Fruits',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/apples.jpg',
    },
    {
      'name': 'Avocado (Hass)',
      'origin': 'Gharb, Morocco',
      'price': '\$3.50/kg',
      'priceValue': 3.50,
      'category': 'Fruits',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/avocado.jpg',
    },

    // --- VEGETABLES (5) ---
    {
      'name': 'Red Tomatoes',
      'origin': 'Agadir, Morocco',
      'price': '\$0.80/kg',
      'priceValue': 0.80,
      'category': 'Vegetables',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/tomatoes.jpg',
    },
    {
      'name': 'Red Onions',
      'origin': 'Hajeb, Morocco',
      'price': '\$0.60/kg',
      'priceValue': 0.60,
      'category': 'Vegetables',
      'isUrgent': true,
      'isOrganic': false,
      'image': 'assets/images/usine/onions.jpg',
    },
    {
      'name': 'Fresh Carrots',
      'origin': 'Berkane, Morocco',
      'price': '\$0.50/kg',
      'priceValue': 0.50,
      'category': 'Vegetables',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/carrots.jpg',
    },
    {
      'name': 'Potatoes (Spunta)',
      'origin': 'Berrechid, Morocco',
      'price': '\$0.70/kg',
      'priceValue': 0.70,
      'category': 'Vegetables',
      'isUrgent': false,
      'isOrganic': false,
      'image': 'assets/images/usine/potatoes.jpg',
    },
    {
      'name': 'Fresh Garlic',
      'origin': 'Taza, Morocco',
      'price': '\$4.00/kg',
      'priceValue': 4.0,
      'category': 'Vegetables',
      'isUrgent': false,
      'isOrganic': true,
      'image': 'assets/images/usine/garlic.jpg',
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((p) {
      bool categoryMatch =
          _selectedCategory == 'All' || p['category'] == _selectedCategory;
      bool urgentMatch = !_urgentOnly || p['isUrgent'] == true;
      bool organicMatch = !_organicOnly || p['isOrganic'] == true;
      bool priceMatch = (p['priceValue'] as double) <= _maxPrice;
      bool searchMatch = _searchQuery.isEmpty ||
          p['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      return categoryMatch &&
          urgentMatch &&
          organicMatch &&
          priceMatch &&
          searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: widget.textLight, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search for seeds, stock, machines...',
                        hintStyle:
                            TextStyle(color: widget.textLight, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(color: widget.textColor, fontSize: 13),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child:
                          Icon(Icons.close, color: widget.textLight, size: 18),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Urgent Sale',
                            style: TextStyle(
                                fontSize: 13,
                                color: widget.textColor,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: _urgentOnly,
                            onChanged: (val) =>
                                setState(() => _urgentOnly = val),
                            activeThumbColor: widget.primaryGreen,
                            activeTrackColor:
                                widget.primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showFilterOptions(context),
                      child: Row(
                        children: [
                          Icon(Icons.tune_outlined,
                              size: 16, color: widget.primaryGreen),
                          const SizedBox(width: 4),
                          Text('Other Filters',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: widget.primaryGreen,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final isSelected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isSelected ? widget.primaryGreen : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? widget.primaryGreen
                                    : Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : widget.textColor,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) =>
                  _buildProductCard(_filteredProducts[i]),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final bool isUrgent = p['isUrgent'] == true;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: p),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Builder(builder: (context) {
                    final img = p['image'] as String;
                    if (img.startsWith('http')) {
                      return Image.network(
                        img,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: const Color(0xFFF1F4F1),
                          child: const Icon(Icons.image_not_supported_outlined,
                              size: 40, color: Colors.grey),
                        ),
                      );
                    }
                    return Image.asset(
                      img,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: const Color(0xFFF1F4F1),
                        child: const Icon(Icons.image_not_supported_outlined,
                            size: 40, color: Colors.grey),
                      ),
                    );
                  }),
                ),
                if (isUrgent)
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on,
                              size: 14, color: widget.primaryGreen),
                          const SizedBox(width: 4),
                          Text('URGENT',
                              style: TextStyle(
                                  color: widget.primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'] as String,
                                style: TextStyle(
                                    color: widget.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14, color: widget.textLight),
                                const SizedBox(width: 4),
                                Text(p['origin'] as String,
                                    style: TextStyle(
                                        color: widget.textLight, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(p['price'] as String,
                              style: TextStyle(
                                  color: widget.primaryGreen,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                          Text('inc. taxes',
                              style: TextStyle(
                                  color: widget.textLight, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 16, color: Colors.orange.shade400),
                          const SizedBox(width: 4),
                          Text('4.8',
                              style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Text('(24 comments)',
                              style: TextStyle(
                                  color: widget.textLight, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailScreen(product: p),
                                ),
                              );
                            },
                            icon: Icon(Icons.info_outline,
                                color: widget.primaryGreen),
                            tooltip: 'View Details',
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _handleOrder(p),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Order Now',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Advanced Filters',
                          style: TextStyle(
                              color: widget.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _organicOnly = false;
                            _maxPrice = 5000;
                          });
                          setState(() {
                            _organicOnly = false;
                            _maxPrice = 5000;
                          });
                        },
                        child: Text('Reset',
                            style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text('Price Range',
                      style: TextStyle(
                          color: widget.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$0',
                          style: TextStyle(
                              color: widget.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text('Up to \$${_maxPrice.toInt()}',
                          style: TextStyle(
                              color: widget.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 20),
                    ),
                    child: Slider(
                      value: _maxPrice,
                      min: 0,
                      max: 5000,
                      activeColor: widget.primaryGreen,
                      inactiveColor: widget.primaryGreen.withValues(alpha: 0.1),
                      onChanged: (val) {
                        setModalState(() => _maxPrice = val);
                        setState(() => _maxPrice = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Organic Products',
                                style: TextStyle(
                                    color: widget.textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Show only certified organic items',
                                style: TextStyle(
                                    color: widget.textLight, fontSize: 11)),
                          ],
                        ),
                        Switch.adaptive(
                          value: _organicOnly,
                          onChanged: (val) {
                            setModalState(() => _organicOnly = val);
                            setState(() => _organicOnly = val);
                          },
                          activeColor: widget.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: widget.primaryGreen.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Apply Selection',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleOrder(Map<String, dynamic> product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OrderProcessingDialog(
        productName: product['name'] as String,
        primaryGreen: widget.primaryGreen,
      ),
    );

    // Simulate network delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Close processing dialog
        _showSuccessSheet(product);
      }
    });
  }

  void _showSuccessSheet(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderSuccessSheet(
        product: product,
        primaryGreen: widget.primaryGreen,
        textColor: widget.textColor,
        textLight: widget.textLight,
        onTrackOrder: () {
          Navigator.pop(context); // Close sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(
                product: product,
                primaryGreen: widget.primaryGreen,
                textColor: widget.textColor,
                textLight: widget.textLight,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────
//  TAB 3 — PROFILE
// ─────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? city;
  final String? companyName;
  final String? productTypes;
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  const _ProfileTab({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.companyName,
    required this.productTypes,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        fullName?.isNotEmpty == true ? fullName! : 'Marcus Thorne';
    final String subtitle = companyName?.isNotEmpty == true
        ? 'CHIEF SUPPLY OFFICER • $companyName'
        : 'CHIEF SUPPLY OFFICER • AGRIFLOW PRO';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avatar Section
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryGreen, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 55,
                        backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=400&auto=format&fit=crop'),
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => debugPrint('Edit Profile Picture'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(name,
                    style: TextStyle(
                        fontSize: 24,
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 2. Account Information
          Text('Account Information',
              style: TextStyle(
                  fontSize: 17, color: textColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _infoTile(Icons.email_outlined, 'EMAIL',
              email ?? 'marcus.thorne@agriflow.io'),
          _infoTile(
              Icons.phone_outlined, 'PHONE', phone ?? '+1 (555) 234-8901'),
          _infoTile(
              Icons.location_on_outlined, 'CITY', city ?? 'Des Moines, IA'),
          _infoTile(Icons.inventory_2_outlined, 'PRODUCT TYPES',
              productTypes ?? 'Grains, Legumes, Soy'),
          const SizedBox(height: 32),

          // 3. Settings Section
          Text('Settings',
              style: TextStyle(
                  fontSize: 17, color: textColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                _settingsTile(Icons.notifications_outlined, 'Notifications',
                    onTap: () => debugPrint('Notifications Settings')),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _settingsTile(Icons.security_outlined, 'Security & Privacy',
                    onTap: () => debugPrint('Security Settings')),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _settingsTile(Icons.language_outlined, 'Language',
                    trailing: 'ENGLISH (US)',
                    onTap: () => debugPrint('Language Settings')),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _settingsTile(Icons.help_outline, 'Help & Support',
                    onTap: () => debugPrint('Help Center')),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 4. Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('SIGN OUT',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: primaryGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: primaryGreen, size: 22),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String label,
      {String? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Color(0xFFF4F6F4), shape: BoxShape.circle),
              child: Icon(icon, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            if (trailing != null)
              Text(trailing,
                  style: TextStyle(
                      color: textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: textLight.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ANIMATED LIVE NETWORK CARD
// ─────────────────────────────────────────────────────────
class LiveNetworkCard extends StatefulWidget {
  const LiveNetworkCard({super.key});

  @override
  State<LiveNetworkCard> createState() => _LiveNetworkCardState();
}

class _LiveNetworkCardState extends State<LiveNetworkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _activeNodes = 12450;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation =
        Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          int change = (DateTime.now().millisecond % 15) - 5;
          _activeNodes += change;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
          color: const Color(0xFF0F3628),
          borderRadius: BorderRadius.circular(28),
          image: const DecorationImage(
            image: NetworkImage(
                'https://www.transparenttextures.com/patterns/world-map.png'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F3628).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ]),
      child: Stack(
        children: [
          Positioned(top: 40, left: 60, child: _buildPulsingDot()),
          Positioned(top: 80, left: 140, child: _buildPulsingDot(delay: 500)),
          Positioned(top: 60, right: 80, child: _buildPulsingDot(delay: 1000)),
          Positioned(bottom: 60, right: 120, child: _buildPulsingDot()),
          Positioned(top: 90, right: 40, child: _buildPulsingDot(delay: 1500)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Live Network',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('Tracking global logistics...',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            FadeTransition(
                              opacity: _pulseAnimation,
                              child: const Icon(Icons.circle,
                                  color: Color(0xFFFF5252), size: 10),
                            ),
                            const SizedBox(width: 5),
                            const Text('LIVE',
                                style: TextStyle(
                                    color: Color(0xFFFF5252),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, -0.3),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          },
                          child: Text(
                            '$_activeNodes',
                            key: ValueKey<int>(_activeNodes),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot({int delay = 0}) {
    return FadeTransition(
      opacity: _pulseAnimation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
            color: const Color(0xFF43EA7A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF43EA7A).withValues(alpha: 0.8),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MODAL & DIALOG COMPONENTS
// ─────────────────────────────────────────────────────────

class _CreateShipmentSheet extends StatelessWidget {
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  const _CreateShipmentSheet({
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "Create New Shipment",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter the shipment details to initiate the logistics flow.",
            style: TextStyle(fontSize: 14, color: textLight),
          ),
          const SizedBox(height: 32),
          _textField("Origin / Port of Loading"),
          const SizedBox(height: 20),
          _textField("Destination / Port of Discharge"),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _textField("Total Weight (kg)")),
              const SizedBox(width: 16),
              Expanded(child: _textField("Container Count")),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Shipment initiated successfully!"),
                    backgroundColor: primaryGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: primaryGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text("Initiate Shipment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textLight, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _OrderProcessingDialog extends StatelessWidget {
  final String productName;
  final Color primaryGreen;

  const _OrderProcessingDialog({
    required this.productName,
    required this.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Processing Order...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Securing your $productName from the supplier. Please wait a moment.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSuccessSheet extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;
  final VoidCallback? onTrackOrder;

  const _OrderSuccessSheet({
    required this.product,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
    this.onTrackOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: primaryGreen, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            "Order Successful!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your order for ${product['name']} has been placed successfully. You will receive an update once the shipment is ready.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Text("Continue Shopping",
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onTrackOrder ?? () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Track Order",
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PRODUCT DETAIL SCREEN (Integrated)
// ─────────────────────────────────────────────────────────

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;

  static const Color primaryGreen = Color(0xFF23763D);
  static const Color bgColor = Color(0xFFF1F8F1);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1A1D1A);
  static const Color textLight = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final String name = p['name'] ?? 'Organic Product';
    final String price = p['price'] ?? '\$0.00';
    final String image = p['image'] ?? 'assets/images/usine/avocado.jpg';
    final String origin = p['origin'] ?? 'Local Farm';
    final bool isOrganic = p['isOrganic'] ?? true;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AgriDirect',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: primaryGreen),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 17,
            backgroundColor: primaryGreen,
            child: CircleAvatar(
              radius: 15,
              backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1535711603865-0a7197029837?q=80&w=100&auto=format&fit=crop'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section with Gradient Overlay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: image.startsWith('http')
                            ? Image.network(image, fit: BoxFit.cover)
                            : Image.asset(image, fit: BoxFit.cover),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.05),
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isOrganic)
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_outlined,
                                    size: 16, color: Color(0xFF2E7D32)),
                                SizedBox(width: 6),
                                Text(
                                  'CERTIFIED ORGANIC',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Favorite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isFavorite = !_isFavorite),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isFavorite
                                ? Colors.red.withOpacity(0.1)
                                : const Color(0xFFEFF5ED),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : primaryGreen,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price and Stock status
                  Row(
                    children: [
                      Text(
                        price.split('/')[0],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '/ unit',
                        style: TextStyle(
                          fontSize: 15,
                          color: textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: primaryGreen.withOpacity(0.1)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded,
                                size: 16, color: primaryGreen),
                            SizedBox(width: 4),
                            Text(
                              'IN STOCK',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Product Story
                  const Text(
                    'PRODUCT STORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: textLight,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      'Hand-picked from the sun-drenched hills of the Central Coast. These premium items are buttery, rich in healthy fats, and grown without synthetic pesticides. Perfect for artisanal toast or a nutrient-dense snack.',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 16,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Farmer Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5ED),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: primaryGreen.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                                'https://images.unsplash.com/photo-1595152772835-219674b2a8a6?q=80&w=100&auto=format&fit=crop'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRODUCED BY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: textLight,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Green Valley Estates',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _openFarmerChat(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDE8DB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_rounded,
                                    size: 18, color: textColor),
                                SizedBox(height: 4),
                                Text(
                                  'Contact\nFarmer',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                            Icons.local_shipping_rounded,
                            'EST. DELIVERY',
                            '24 – 48 Hours'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                            Icons.location_on_rounded, 'ORIGIN', origin),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Harvest Statistics
                  Row(
                    children: [
                      const Text(
                        'Harvest Statistics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.withOpacity(0.2),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatCard('92%', 'OIL CONTENT',
                      'Exceptional creaminess and stability for culinary use.',
                      accentColor: const Color(0xFF1B5E20)),
                  const SizedBox(height: 16),
                  _buildStatCard('320g', 'AVG. WEIGHT',
                      'Large size fruits with minimal stone-to-flesh ratio.',
                      accentColor: const Color(0xFF880E4F)),
                  const SizedBox(height: 16),
                  _buildStatCard('A++', 'SUSTAINABILITY',
                      'Carbon-negative orchard practices with water recycling.',
                      accentColor: const Color(0xFF006064)),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('PLACE ORDER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: textLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, String subtitle,
      {Color accentColor = primaryGreen}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: textLight,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openFarmerChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IntegratedFarmerChatSheet(farmerName: 'Green Valley Estates'),
    );
  }
}

class _IntegratedFarmerChatSheet extends StatelessWidget {
  final String farmerName;

  const _IntegratedFarmerChatSheet({required this.farmerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1595152772835-219674b2a8a6?q=80&w=100&auto=format&fit=crop'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Online • Typically responds in 5m',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildMessage(
                  'Hello! I\'m interested in your Organic Avocados. Are they available for bulk shipping?',
                  isMe: true,
                ),
                _buildMessage(
                  'Hello! Yes, they are. We just harvested a fresh batch this morning. How many units are you looking for?',
                  isMe: false,
                ),
                _buildMessage(
                  'I need around 500 units for our factory next week.',
                  isMe: true,
                ),
                _buildMessage(
                  'That shouldn\'t be a problem. I can offer you a wholesale discount for that quantity. Would you like me to send a formal quote?',
                  isMe: false,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F4),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF23763D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF23763D) : const Color(0xFFF4F6F4),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            height: 1.4,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ORDER TRACKING SCREEN (Integrated)
// ─────────────────────────────────────────────────────────

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  const OrderTrackingScreen({
    super.key,
    required this.product,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Details',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: primaryGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tracking ID Card ──────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRACKING ID',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF757575),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '#ORD-5529-X',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'In Transit',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8F1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.calendar_today_rounded,
                            color: primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Delivery',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Oct 30, 2023',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ── Live Journey ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route_rounded,
                          color: primaryGreen, size: 28),
                      const SizedBox(width: 14),
                      const Text(
                        'Live Journey',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1D1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildTimelineStep(
                    primaryGreen: primaryGreen,
                    textColor: textColor,
                    icon: Icons.description_outlined,
                    title: 'Order Placed',
                    subtitle: 'Oct 24, 2023 \u2022 09:15 AM',
                    isCompleted: true,
                  ),
                  _buildTimelineStep(
                    primaryGreen: primaryGreen,
                    textColor: textColor,
                    icon: Icons.factory_outlined,
                    title: 'Factory Processing',
                    subtitle: 'Oct 26, 2023 \u2022 02:30 PM',
                    isCompleted: true,
                  ),
                  _buildTimelineStep(
                    primaryGreen: primaryGreen,
                    textColor: textColor,
                    icon: Icons.local_shipping_outlined,
                    title: 'In Transit',
                    subtitle: 'Moving through Heartland Hub, KS',
                    isActive: true,
                    isCompleted: true,
                  ),
                  // Map snippet
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 52, top: 5, bottom: 25),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: const Color(0xFFE8F5E9),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          children: [
                            // Map background
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MapPainter(),
                              ),
                            ),
                            // Live route badge
                            Positioned(
                              bottom: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'LIVE ROUTE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // FACTORY label
                            const Positioned(
                              top: 20,
                              right: 25,
                              child: Text(
                                'FACTORY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2E7D32),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildTimelineStep(
                    primaryGreen: primaryGreen,
                    textColor: textColor,
                    icon: Icons.home_work_outlined,
                    title: 'Delivered to Factory',
                    subtitle: 'Estimated Oct 30',
                    isLast: true,
                    isCompleted: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // ── Order Summary ─────────────────────────────
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryItem(
              primaryGreen: primaryGreen,
              icon: Icons.eco_rounded,
              title: product['name'] as String? ?? 'Organic Produce',
              subtitle: 'Batch #VG-992',
              quantity: '5 Tons',
            ),
            const SizedBox(height: 14),
            _buildSummaryItem(
              primaryGreen: primaryGreen,
              icon: Icons.science_rounded,
              title: 'Fertilizer',
              subtitle: 'Nitrogen Rich Mix',
              quantity: '2 Tons',
            ),
            const SizedBox(height: 35),

            // ── Total Value ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(35),
                border:
                    Border.all(color: primaryGreen.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Value',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Insured Logistics',
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$12,450.00',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'USD',
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required Color primaryGreen,
    required Color textColor,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLast = false,
    bool isActive = false,
    bool isCompleted = false,
  }) {
    final Color circleColor = isActive || isCompleted
        ? const Color(0xFF2E7D32)
        : const Color(0xFFEFF5ED);
    final Color titleColor = isActive
        ? const Color(0xFF2E7D32)
        : (isCompleted ? textColor : const Color(0xFFBDBDBD));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ]
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: isActive ? 260 : 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF2E7D32).withOpacity(0.2)
                      : const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required Color primaryGreen,
    required IconData icon,
    required String title,
    required String subtitle,
    required String quantity,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5ED),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: primaryGreen, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D1A))),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF757575))),
              ],
            ),
          ),
          Text(
            quantity,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter for map background ──────────────────────
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFD8EDD8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFB8D8B8)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw dashed route
    final routePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.8)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.2,
        size.width * 0.65,
        size.height * 0.8,
        size.width * 0.85,
        size.height * 0.2,
      );

    // Dashed path
    const dashLen = 10.0;
    const gapLen = 6.0;
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), routePaint);
        dist += dashLen + gapLen;
      }
    }

    // Draw truck dot (active position)
    final dotPaint = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5), 8, dotPaint);
    final dotOuterPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5), 16, dotOuterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bottom Nav Widget ───────────────────────────────────────
class _TrackingBottomNav extends StatelessWidget {
  final Color primaryGreen;
  const _TrackingBottomNav({required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.storefront_outlined, 'MARKET', false),
          _navItem(Icons.local_shipping_rounded, 'ORDERS', true),
          _navItem(Icons.agriculture_outlined, 'FLEET', false),
          _navItem(Icons.person_outline, 'ACCOUNT', false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    if (active) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                  letterSpacing: 0.5)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF757575), size: 26),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF757575),
                letterSpacing: 0.5)),
      ],
    );
  }
}
