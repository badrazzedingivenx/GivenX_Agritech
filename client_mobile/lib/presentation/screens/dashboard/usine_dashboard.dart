import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/shared_profile_tab.dart';
import '../chat/conversations_screen.dart';
import '../register/orders_page.dart';

// ─────────────────────────────────────────────────────────
//  MAIN SHELL — controls which tab is active
// ─────────────────────────────────────────────────────────

class UsineDashboard extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String companyName;
  final String productTypes;
  final String buyerType; // 'restaurant' or 'industry'
  final int? userId;

  const UsineDashboard({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.companyName,
    required this.productTypes,
    this.buyerType = 'restaurant',
    this.userId,
  });

  @override
  State<UsineDashboard> createState() => _UsineDashboardState();
}

class _UsineDashboardState extends State<UsineDashboard> {
  int _currentIndex = 0; // 0=Home, 1=Shipments, 2=Marketplace, 3=Messages, 4=Profile
  int _shipmentsVersion = 0;
  int _unreadMessagesCount = 0;
  static const Duration _badgePollInterval = Duration(seconds: 10);
  Timer? _badgeTimer;

  static const Color primaryGreen = Color(0xFF23763D);
  static const Color textColor = Color(0xFF1A1D1A);
  static const Color textLight = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _startUnreadBadgePolling();
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  void _startUnreadBadgePolling() {
    _loadUnreadMessagesCount();
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(_badgePollInterval, (_) {
      if (!mounted || _currentIndex == 3) return;
      _loadUnreadMessagesCount();
    });
  }

  Future<void> _loadUnreadMessagesCount() async {
    try {
      final user = await SessionService.getUser();
      if (user == null) return;
      final received = await ApiService.getMessages(receiverId: '${user.id}');
      final unread = received.where((m) => (m as Map<String, dynamic>)['isRead'] == false).length;
      if (!mounted) return;
      setState(() => _unreadMessagesCount = unread);
    } catch (_) {}
  }

  void _onTabSelected(int i) {
    setState(() {
      _currentIndex = i;
      if (i == 3) {
        _unreadMessagesCount = 0;
      }
    });
    if (i != 3) {
      _loadUnreadMessagesCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
      widget.fullName.isNotEmpty ? widget.fullName : 'Alexander';

    return DashboardScaffold(
      currentIndex: _currentIndex,
      userRole: 'Buyer',
      userId: widget.userId,
      navBadgeCounts: {3: _unreadMessagesCount},
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.eco_outlined, label: 'Shipments'),
        NavItem(icon: Icons.shopping_cart_outlined, label: 'Marketplace'),
        NavItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      onTabSelected: _onTabSelected,
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            displayName: displayName,
            primaryGreen: primaryGreen,
            textColor: textColor,
            textLight: textLight,
            onTabChange: (i) => setState(() => _currentIndex = i),
            userId: widget.userId,
            buyerType: widget.buyerType,
          ),
          _ShipmentsTab(
            key: ValueKey(_shipmentsVersion),
            primaryGreen: primaryGreen,
            textColor: textColor,
            textLight: textLight,
            userId: widget.userId,
            buyerType: widget.buyerType,
          ),
          _MarketplaceTab(
            primaryGreen: primaryGreen,
            textColor: textColor,
            textLight: textLight,
            onNavigateToShipments: () => setState(() => _currentIndex = 1),
            enableBulkSourcing: widget.buyerType.toLowerCase() == 'industry',
            buyerType: widget.buyerType,
          ),
          const ConversationsScreen(),
          SharedProfileTab(
            fullName: widget.fullName,
            subtitle: '${widget.buyerType == "industry" ? "INDUSTRY BUYER" : "RESTAURANT BUYER"} • ${widget.companyName}',
            primaryGreen: primaryGreen,
            textColor: textColor,
            textLight: textLight,
            infoItems: [
              ProfileInfoItem(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF1565C0),
                label: 'EMAIL',
                value: widget.email,
              ),
              ProfileInfoItem(
                icon: Icons.phone_outlined,
                iconColor: const Color(0xFFE65100),
                label: 'PHONE',
                value: widget.phone,
              ),
              ProfileInfoItem(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFFAD1457),
                label: 'CITY',
                value: widget.city,
              ),
              ProfileInfoItem(
                icon: Icons.business_outlined,
                iconColor: const Color(0xFF00695C),
                label: 'COMPANY',
                value: widget.companyName,
              ),
              ProfileInfoItem(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF6A1B9A),
                label: 'PRODUCT TYPES',
                value: widget.productTypes,
              ),
            ],
          ),
        ],
      ),
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
        buyerId: widget.userId,
        buyerType: widget.buyerType,
        onCreated: () => setState(() => _shipmentsVersion++),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TAB 0 — HOME
// ─────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final String displayName;
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  final Function(int)? onTabChange;
  final int? userId;
  final String buyerType;

  const _HomeTab({
    required this.displayName,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
    this.onTabChange,
    this.userId,
    this.buyerType = 'restaurant',
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Map<String, dynamic>> _shipments = [];
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  bool get _isIndustry => widget.buyerType.toLowerCase() == 'industry';

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1280) return 4;
    if (width >= 900) return 3;
    if (width >= 420) return 2;
    return 1;
  }

  double _gridAspectRatio(BuildContext context) {
    final columns = _gridColumns(context);
    if (columns >= 4) return 0.95;
    if (columns == 3) return 0.92;
    if (columns == 2) return 0.98;
    return 1.16;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final buyerIdStr = widget.userId?.toString();
      final buyerType = widget.buyerType.toLowerCase();
      final results = await Future.wait([
        ApiService.getShipments(),
        ApiService.getOrders(buyerId: buyerIdStr),
      ]);
      final allShipments = results[0].cast<Map<String, dynamic>>();
      final rawBuyerOrders = results[1].cast<Map<String, dynamic>>();
      final buyerOrders = rawBuyerOrders.where((order) {
        final orderBuyerType = (order['buyerType'] ?? '').toString().toLowerCase();
        return orderBuyerType == buyerType;
      }).toList();
      final orderIds = buyerOrders
          .map((o) => (o['id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();
      final buyerShipments = widget.userId == null
          ? allShipments
          : allShipments.where((shipment) {
              final orderId = (shipment['orderId'] as num?)?.toInt();
              return orderId != null && orderIds.contains(orderId);
            }).toList();
      if (mounted) {
        setState(() {
          _shipments = buyerShipments;
          _orders = buyerOrders;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _shipmentCount => _shipments.length;
  int get _inTransitCount => _shipments.where((s) => s['status'] == 'inTransit').length;
  int get _deliveredCount => _shipments.where((s) => s['status'] == 'delivered').length;
  int get _recentOrderCount => _orders.where((o) => o['status'] == 'processing' || o['status'] == 'pending').length;

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered': return 'DELIVERED';
      case 'inTransit': return 'IN TRANSIT';
      case 'requested': return 'REQUESTED';
      default: return status.toUpperCase();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered': return widget.primaryGreen;
      case 'inTransit': return Colors.orange;
      case 'requested': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text('BUYER DASHBOARD',
              style: TextStyle(
                color: widget.primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
          const SizedBox(height: 6),
            Text('Hello, ${widget.displayName}',
              style: TextStyle(
                  fontSize: 28,
                  color: widget.textColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(
              _isIndustry
                  ? 'Here is your industrial sourcing and shipment status today.'
                  : 'Here is your restaurant ordering and delivery status today.',
              style: TextStyle(color: widget.textLight, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTabChange?.call(2),
                  child: _buildActionButton(
                      'Marketplace',
                      Icons.shopping_cart_outlined,
                      false),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isIndustry) {
                      widget.onTabChange?.call(1);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrdersPage()),
                      );
                    }
                  },
                  child: _buildActionButton(
                    _isIndustry ? 'Track\nShipments' : 'Track\nOrders',
                    _isIndustry ? Icons.local_shipping_outlined : Icons.receipt_long_outlined,
                    true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: _gridColumns(context),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: _gridAspectRatio(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                  icon: Icons.local_shipping,
                  iconBgColor: const Color(0xFFDDF1E3),
                  iconColor: widget.primaryGreen,
                  value: _loading ? '...' : '$_shipmentCount',
                  title: _isIndustry ? 'Sourcing Shipments' : 'Delivery Shipments',
                  badge: _inTransitCount > 0 ? '$_inTransitCount in transit' : null),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersPage()),
                  );
                },
                child: _buildStatCard(
                    icon: Icons.shopping_cart,
                    iconBgColor: const Color(0xFFFCEAE8),
                    iconColor: const Color(0xFFB52B35),
                    value: _loading ? '...' : '$_recentOrderCount',
                    title: _isIndustry ? 'Open Procurement Orders' : 'Pending Orders'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LiveNetworkCard(
            loading: _loading,
            totalShipments: _shipmentCount,
            inTransitShipments: _inTransitCount,
            pendingOrders: _recentOrderCount,
          ),
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
                      color: widget.textColor,
                      fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: () => widget.onTabChange?.call(1),
                child: Text('View All',
                    style: TextStyle(
                        color: widget.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_shipments.isEmpty)
            Center(child: Text('No shipments yet', style: TextStyle(color: widget.textLight)))
          else
            GridView.count(
              crossAxisCount: _gridColumns(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: _gridAspectRatio(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _shipments.take(4).map((s) => _buildBatchItem(
                icon: Icons.inventory_2,
                title: 'Shipment #${s['id']}',
                subtitle: '${s['pickupLocation'] ?? ''} → ${s['deliveryLocation'] ?? ''}',
                statusText: _statusLabel(s['status'] ?? ''),
                statusBgColor: _statusColor(s['status'] ?? ''),
                statusTextColor: Colors.white,
              )).toList(),
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
        color: isPrimary ? widget.primaryGreen : Colors.white,
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
          Icon(icon, color: isPrimary ? Colors.white : widget.textColor, size: 20),
          const SizedBox(width: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isPrimary ? Colors.white : widget.textColor,
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
      padding: const EdgeInsets.all(16),
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
                          color: widget.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 24, color: widget.textColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: widget.textLight, fontSize: 12)),
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
            Text(_isIndustry ? 'Industrial Marketplace' : 'Restaurant Marketplace',
                style: TextStyle(
                    fontSize: 18,
                    color: widget.textColor,
                    fontWeight: FontWeight.w800)),
            GestureDetector(
              onTap: () => widget.onTabChange?.call(2),
              child: Text('View All',
                  style: TextStyle(
                      color: widget.primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => widget.onTabChange?.call(2),
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
                        color: widget.textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: widget.textLight, fontSize: 12)),
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
        color: widget.primaryGreen,
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
                  text: TextSpan(
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    children: [
                      TextSpan(text: _isIndustry ? 'You have completed ' : 'You have delivered '),
                      TextSpan(
                          text: '$_deliveredCount delivered',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: _isIndustry
                              ? ' sourcing shipments out of $_shipmentCount total. $_inTransitCount currently in transit.'
                              : ' shipments out of $_shipmentCount total. $_inTransitCount currently in transit.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showLogisticsReport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: widget.primaryGreen,
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
                      color: widget.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.analytics_outlined,
                        color: widget.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Supply Chain Report',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                        Text('Shipment & Order Summary',
                            style: TextStyle(
                                color: Color(0xFF757575), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _reportItem('Total Shipments', '$_shipmentCount', Icons.local_shipping,
                  Colors.green.shade700),
              _reportItem('Delivered', '$_deliveredCount',
                  Icons.check_circle_outline, Colors.blue.shade700),
              _reportItem('Pending Orders', '$_recentOrderCount', Icons.pending_actions,
                  Colors.orange.shade700),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryGreen,
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
  final int? userId;
  final String buyerType;

  const _ShipmentsTab({
    super.key,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
    this.userId,
    this.buyerType = 'restaurant',
  });

  @override
  State<_ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends State<_ShipmentsTab> {
  String _activeFilter = 'All Shipments';
  final List<String> _filters = ['All Shipments', 'In Transit', 'Delivered'];
  final Set<String> _expandedIds = {};
  List<Map<String, dynamic>> _shipmentData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    try {
      final buyerIdStr = widget.userId?.toString();
      final buyerType = widget.buyerType.toLowerCase();

      final results = await Future.wait([
        ApiService.getShipments(),
        if (buyerIdStr != null)
          ApiService.getOrders(buyerId: buyerIdStr)
        else
          Future.value(<dynamic>[]),
      ]);

      final rawShipments = results[0].cast<Map<String, dynamic>>();
      final buyerOrders = results[1].cast<dynamic>().map((e) => e as Map<String, dynamic>).where((o) {
        final orderBuyerType = (o['buyerType'] ?? '').toString().toLowerCase();
        return orderBuyerType == buyerType;
      }).toList();

      final orderIds = buyerOrders
          .map((o) => (o['id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();

      final scopedShipments = widget.userId == null
          ? rawShipments
          : rawShipments.where((s) {
              final shipmentBuyerId = (s['buyerId'] as num?)?.toInt();
              final shipmentBuyerType = (s['buyerType'] ?? '').toString().toLowerCase();
              final shipmentOrderId = (s['orderId'] as num?)?.toInt();

              final matchesBuyer = shipmentBuyerId != null && shipmentBuyerId == widget.userId;
              final matchesOrder = shipmentOrderId != null && orderIds.contains(shipmentOrderId);
              final matchesType = shipmentBuyerType.isEmpty || shipmentBuyerType == buyerType;
              return (matchesBuyer || matchesOrder) && matchesType;
            }).toList();

      final shipments = scopedShipments.map((s) {
        final status = (s['status'] ?? 'requested').toString();
        final weightKg = (s['weight'] as num?)?.toDouble() ?? 0;
        final statusLabel = _statusLabel(status);
        final colors = _statusColors(status);
        return {
          'id': '#SHP-${s['id']}',
          'destination': s['deliveryLocation'] ?? '',
          'weight': '${weightKg.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} kg',
          'weightKg': weightKg,
          'date': s['estimatedDeliveryDate'] != null
              ? _formatDate(DateTime.parse(s['estimatedDeliveryDate']))
              : 'TBD',
          'status': statusLabel,
          'statusColor': colors['bg'],
          'statusText': colors['text'],
          'icon': _statusIcon(status),
          'rawStatus': status,
        };
      }).toList();
      if (mounted) setState(() { _shipmentData = shipments; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered': return 'DELIVERED';
      case 'inTransit': return 'IN TRANSIT';
      case 'pickedUp': return 'PICKED UP';
      case 'accepted': return 'ACCEPTED';
      case 'cancelled': return 'CANCELLED';
      default: return 'PROCESSING';
    }
  }

  Map<String, Color> _statusColors(String status) {
    switch (status) {
      case 'delivered':
        return {'bg': const Color(0xFFE8F5E9), 'text': const Color(0xFF2E7D32)};
      case 'inTransit':
        return {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFEF6C00)};
      case 'pickedUp':
        return {'bg': const Color(0xFFE3F2FD), 'text': const Color(0xFF1565C0)};
      default:
        return {'bg': const Color(0xFFF3E5F5), 'text': const Color(0xFF7B1FA2)};
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'delivered': return Icons.check_circle_outline;
      case 'inTransit': return Icons.local_shipping;
      case 'pickedUp': return Icons.inventory_2;
      default: return Icons.home_work;
    }
  }

  List<Map<String, dynamic>> get _filteredShipments {
    if (_activeFilter == 'All Shipments') return _shipmentData;
    return _shipmentData.where((s) => s['status'] == _activeFilter.toUpperCase()).toList();
  }

  double get _totalWeightKg =>
      _shipmentData.fold<double>(0, (sum, s) => sum + ((s['weightKg'] as num?)?.toDouble() ?? 0));

  int get _deliveredCount =>
      _shipmentData.where((s) => s['status'] == 'DELIVERED').length;

  double get _deliveredRate {
    if (_shipmentData.isEmpty) return 0;
    return (_deliveredCount / _shipmentData.length) * 100;
  }

  String _formatWeight(double kg) {
    if (kg >= 1000) {
      return '${(kg / 1000).toStringAsFixed(1)} tons';
    }
    return '${kg.toStringAsFixed(0)} kg';
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
                    Text(_loading ? '...' : '${_shipmentData.length}',
                        style: const TextStyle(
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
                      child: Text(_loading ? '...' : '${_deliveredRate.toStringAsFixed(0)}% delivered',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    _loading ? 'Total weight: ...' : 'Total weight: ${_formatWeight(_totalWeightKg)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _smallStats(
                      'Delivered',
                      _loading ? '...' : '${_shipmentData.where((s) => s['status'] == 'DELIVERED').length}',
                      Icons.check_circle_outline,
                      const Color(0xFFE8F5E9),
                      const Color(0xFF2E7D32))),
              const SizedBox(width: 16),
              Expanded(
                  child: _smallStats(
                      'In Transit',
                      _loading ? '...' : '${_shipmentData.where((s) => s['status'] == 'IN TRANSIT').length}',
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
  final bool enableBulkSourcing;
  final String buyerType;

  const _MarketplaceTab({
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
    this.onNavigateToShipments,
    this.enableBulkSourcing = false,
    this.buyerType = 'restaurant',
  });

  @override
  State<_MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<_MarketplaceTab> {
  int _activeSection = 0;
  static const Duration _bulkPollInterval = Duration(seconds: 8);
  Timer? _bulkTimer;

  String _selectedCategory = 'All';
  bool _urgentOnly = false;
  bool _organicOnly = false;
  double _maxPrice = 5000;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = true;
  bool _ordersLoading = true;

  List<String> _categories = ['All'];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _buyerOrders = [];
  final Set<int> _escrowPaidOrderIds = <int>{};
  List<Map<String, dynamic>> _bulkRequests = [];
  Map<int, List<Map<String, dynamic>>> _offersByRequest = {};
  bool _bulkLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.enableBulkSourcing) {
      _loadBuyerOrders();
      _loadBulkMarketplaceData();
      _startBulkPolling();
    } else {
      _ordersLoading = false;
    }
  }

  @override
  void dispose() {
    _bulkTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startBulkPolling() {
    _bulkTimer?.cancel();
    _bulkTimer = Timer.periodic(_bulkPollInterval, (_) {
      if (!mounted || !widget.enableBulkSourcing || _activeSection != 1) return;
      _loadBulkMarketplaceData(silent: true);
    });
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService.getProducts();
      final products = data.map((e) {
        final p = e as Map<String, dynamic>;
        final catRaw = p['category'] is Map ? (p['category']['name'] ?? 'other') : (p['category'] ?? 'other');
        final catName = catRaw.toString().trim();
        final normalizedCategory = catName.isEmpty ? 'other' : catName;
        final catLabel = normalizedCategory[0].toUpperCase() + normalizedCategory.substring(1);
        return {
          'id': p['id'],
          'name': p['name'] ?? '',
          'origin': p['location'] ?? '',
          'price': '${(p['price'] as num?)?.toDouble() ?? 0} MAD',
          'priceValue': (p['price'] as num?)?.toDouble() ?? 0,
          'category': catLabel,
          'isUrgent': p['isUrgent'] ?? false,
          'isOrganic': p['isOrganic'] ?? false,
          'isAvailable': p['isAvailable'] ?? true,
          'quantity': (p['quantity'] as num?)?.toDouble() ?? 0,
          'image': p['image'] ?? '',
          'farmerId': p['sellerId'] ?? p['farmerId'],
          'farmerName': p['sellerName'] ?? p['farmerName'] ?? 'Farmer',
          'unit': p['unit'] ?? 'Kg',
        };
      }).toList();

      final cats = <String>{'All'};
      for (final p in products) {
        cats.add(p['category'] as String);
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          _categories = cats.toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBuyerOrders() async {
    if (!widget.enableBulkSourcing) {
      if (mounted) {
        setState(() {
          _buyerOrders = [];
          _ordersLoading = false;
        });
      }
      return;
    }

    try {
      final user = await SessionService.getUser();
      if (user == null) {
        if (mounted) {
          setState(() {
            _buyerOrders = [];
            _ordersLoading = false;
          });
        }
        return;
      }

      final orders = await ApiService.getOrders(buyerId: '${user.id}');
      final buyerType = widget.buyerType.toLowerCase();
      final filteredOrders = orders.where((entry) {
        final map = entry as Map<String, dynamic>;
        final orderBuyerType = (map['buyerType'] ?? '').toString().toLowerCase();
        return orderBuyerType == buyerType;
      }).toList();
      if (!mounted) return;
      setState(() {
        _buyerOrders = filteredOrders.cast<Map<String, dynamic>>();
        _ordersLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _ordersLoading = false);
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _loadBulkMarketplaceData({bool silent = false}) async {
    if (!widget.enableBulkSourcing) return;

    if (mounted && !silent) {
      setState(() => _bulkLoading = true);
    }

    try {
      final user = await SessionService.getUser();
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _bulkRequests = [];
          _offersByRequest = {};
          _bulkLoading = false;
        });
        return;
      }

      final requestsRaw = await ApiService.getBulkRequests(
        buyerId: '${user.id}',
        buyerType: widget.buyerType.toLowerCase(),
      );

      final requests = requestsRaw
          .map((e) => (e as Map<String, dynamic>))
          .where((r) {
            final status = (r['status'] ?? '').toString().toLowerCase();
            final acceptedOfferId = _asInt(r['acceptedOfferId']);
            return status == 'open' && acceptedOfferId == null;
          })
          .toList()
        ..sort((a, b) {
          final aDate = DateTime.tryParse((a['createdAt'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse((b['createdAt'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      final offersRaw = await ApiService.getBulkOffers();
      final offers = offersRaw.map((e) => (e as Map<String, dynamic>)).toList();

      final grouped = <int, List<Map<String, dynamic>>>{};
      for (final offer in offers) {
        final requestId = _asInt(offer['requestId']);
        if (requestId == null) continue;
        grouped.putIfAbsent(requestId, () => []).add(offer);
      }

      for (final reqOffers in grouped.values) {
        reqOffers.sort((a, b) {
          final aPrice = (a['pricePerUnit'] as num?)?.toDouble() ?? double.infinity;
          final bPrice = (b['pricePerUnit'] as num?)?.toDouble() ?? double.infinity;
          return aPrice.compareTo(bPrice);
        });
      }

      if (!mounted) return;
      setState(() {
        _bulkRequests = requests;
        _offersByRequest = grouped;
        _bulkLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _bulkLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _offersForRequest(Map<String, dynamic> request) {
    final requestId = _asInt(request['id']);
    if (requestId == null) return const [];
    final requestCreatedAt = DateTime.tryParse((request['createdAt'] ?? '').toString());

    final offers = List<Map<String, dynamic>>.from(_offersByRequest[requestId] ?? const [])
        .where((offer) {
          if (requestCreatedAt == null) return true;
          final offerCreatedAt = DateTime.tryParse((offer['createdAt'] ?? '').toString());
          if (offerCreatedAt == null) return false;
          return !offerCreatedAt.isBefore(requestCreatedAt);
        })
        .toList();

    offers.sort((a, b) {
      final aPrice = (a['pricePerUnit'] as num?)?.toDouble() ?? double.infinity;
      final bPrice = (b['pricePerUnit'] as num?)?.toDouble() ?? double.infinity;
      return aPrice.compareTo(bPrice);
    });
    return offers;
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((p) {
      bool categoryMatch =
          _selectedCategory == 'All' || p['category'] == _selectedCategory;
      bool urgentMatch = !_urgentOnly || p['isUrgent'] == true;
      bool organicMatch = !_organicOnly || p['isOrganic'] == true;
      bool availabilityMatch = (p['isAvailable'] == true) && ((p['quantity'] as double? ?? 0) > 0);
      bool priceMatch = (p['priceValue'] as double) <= _maxPrice;
      final query = _searchQuery.trim().toLowerCase();
      bool searchMatch = query.isEmpty ||
        p['name'].toString().toLowerCase().contains(query) ||
        p['farmerName'].toString().toLowerCase().contains(query) ||
        p['origin'].toString().toLowerCase().contains(query);

      return categoryMatch &&
          urgentMatch &&
          organicMatch &&
          availabilityMatch &&
          priceMatch &&
          searchMatch;
    }).toList();
  }

  int _gridColumns(double width) {
    if (width >= 1024) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  Future<void> _payToEscrow(Map<String, dynamic> order) async {
    final orderId = (order['id'] as num?)?.toInt();
    if (orderId == null) return;

    final user = await SessionService.getUser();
    if (user == null) return;

    final amount = (order['totalAmount'] as num?)?.toDouble() ?? 0;

    try {
      await ApiService.createPayment({
        'orderId': orderId,
        'userId': user.id,
        'amount': amount,
        'method': 'bank_transfer',
        'status': 'held_in_escrow',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await ApiService.updateOrder(orderId, {
        'status': 'requested',
      });

      if (!mounted) return;
      setState(() => _escrowPaidOrderIds.add(orderId));
      _loadBuyerOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Escrow funded successfully'),
          backgroundColor: widget.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create escrow payment')),
      );
    }
  }

  void _openCreateBulkRequestSheet() {
    if (!widget.enableBulkSourcing) return;

    final formKey = GlobalKey<FormState>();
    final productCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String selectedUnit = 'Kg';
    DateTime deadline = DateTime.now().add(const Duration(days: 7));

    // Capture outer scaffold messenger before async context changes
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Bulk Sourcing Request',
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: productCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final qty = double.tryParse(v ?? '');
                              if (qty == null || qty <= 0) return 'Invalid quantity';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            items: const [
                              DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                              DropdownMenuItem(value: 'Ton', child: Text('Ton')),
                              DropdownMenuItem(value: 'Box', child: Text('Box')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              modalSetState(() => selectedUnit = v);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: budgetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Max Budget / Unit (MAD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: modalContext,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                          initialDate: deadline,
                        );
                        if (picked != null) {
                          modalSetState(() => deadline = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Deadline',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${deadline.day}/${deadline.month}/${deadline.year}',
                          style: TextStyle(color: widget.textColor, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting ? null : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;

                          modalSetState(() => submitting = true);

                          try {
                            final user = await SessionService.getUser();
                            if (user == null) {
                              modalSetState(() => submitting = false);
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Session expired — please log in again')),
                              );
                              return;
                            }

                            final qty = double.parse(qtyCtrl.text.trim());
                            final budget = double.tryParse(budgetCtrl.text.trim()) ?? 0;

                            final createdRequest = await ApiService.createBulkRequest({
                              'buyerId': user.id,
                              'buyerName': user.fullName,
                              'buyerType': widget.buyerType.toLowerCase(),
                              'productName': productCtrl.text.trim(),
                              'quantity': qty,
                              'unit': selectedUnit,
                              'budget': budget,
                              'deadline': deadline.toIso8601String(),
                              'status': 'open',
                              'acceptedOfferId': null,
                              'createdAt': DateTime.now().toIso8601String(),
                            });

                            Navigator.pop(modalContext);
                            await _loadBulkMarketplaceData();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: const Text('Bulk request published. Waiting for farmer offers.'),
                                backgroundColor: widget.primaryGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            modalSetState(() => submitting = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publish Request'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptOffer(int requestId, int offerId) async {
    if (!widget.enableBulkSourcing) return;

    try {
      if (mounted) {
        setState(() => _bulkLoading = true);
      }

      final request = _bulkRequests.where((r) => _asInt(r['id']) == requestId).cast<Map<String, dynamic>>().toList();
      if (request.isEmpty) {
        if (mounted) setState(() => _bulkLoading = false);
        return;
      }

      final offers = _offersForRequest(request.first);
      final selectedOffer = offers.where((o) => _asInt(o['id']) == offerId).cast<Map<String, dynamic>>().toList();
      for (final offer in offers) {
        final currentId = _asInt(offer['id']);
        if (currentId == null) continue;
        final nextStatus = currentId == offerId ? 'accepted' : 'rejected';
        await ApiService.updateBulkOffer(currentId, {
          'status': nextStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await ApiService.updateBulkRequest(requestId, {
        'status': 'in_progress',
        'acceptedOfferId': offerId,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final buyer = await SessionService.getUser();
      final farmerId = selectedOffer.isNotEmpty ? _asInt(selectedOffer.first['farmerId']) : null;
      final farmerName = selectedOffer.isNotEmpty ? (selectedOffer.first['farmerName'] ?? 'Farmer').toString() : 'Farmer';
      final productName = request.isNotEmpty ? (request.first['productName'] ?? 'your request').toString() : 'your request';

      if (buyer != null && farmerId != null) {
        await ApiService.sendMessage({
          'senderId': buyer.id,
          'senderName': buyer.fullName,
          'receiverId': farmerId,
          'receiverName': farmerName,
          'content': 'Your bulk offer for $productName was accepted. Please continue in chat.',
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      await _loadBulkMarketplaceData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Offer accepted and request updated'),
          backgroundColor: widget.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _bulkLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept offer')),
      );
    }
  }

  void _openOfferSelectionSheet(int requestId, List<Map<String, dynamic>> offers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose supplier offer',
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final offer = offers[i];
                  final offerId = _asInt(offer['id']);
                  final farmerName = (offer['farmerName'] ?? 'Farmer').toString();
                  final price = (offer['pricePerUnit'] as num?)?.toDouble() ?? 0;
                  final qty = (offer['proposedQuantity'] as num?)?.toDouble() ?? 0;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farmerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${price.toStringAsFixed(2)} MAD/unit • Qty ${qty.toStringAsFixed(0)}',
                                style: TextStyle(color: widget.textLight, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: offerId == null
                              ? null
                              : () {
                                  Navigator.pop(sheetContext);
                                  _acceptOffer(requestId, offerId);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _gridColumns(width);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.enableBulkSourcing)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                _sectionPill('Products', 0),
                const SizedBox(width: 8),
                _sectionPill('Bulk Sourcing', 1),
              ],
            ),
          ),
          if (!widget.enableBulkSourcing || _activeSection == 0) ...[
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
                        hintText: 'Search products, farmer, or origin...',
                        hintStyle:
                            TextStyle(color: widget.textLight, fontSize: 13),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: true,
                        fillColor: Colors.transparent,
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
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No products found')),
            )
          else
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
          ] else if (widget.enableBulkSourcing && _activeSection == 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bulk Requests',
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openCreateBulkRequestSheet,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_bulkLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_bulkRequests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No bulk requests yet')),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _bulkRequests.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: width < 480 ? 2 : crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: width < 480 ? 1.0 : (width < 900 ? 1.0 : 0.95),
                      ),
                      itemBuilder: (context, index) {
                        final request = _bulkRequests[index];
                        final requestId = _asInt(request['id']) ?? -1;
                        final offers = requestId == -1
                            ? <Map<String, dynamic>>[]
                          : _offersForRequest(request);
                        final actionableOffers = offers
                          .where((o) => (o['status'] ?? 'pending').toString().toLowerCase() == 'pending')
                          .toList();
                        final bestOfferId = actionableOffers.isEmpty ? -1 : (_asInt(actionableOffers.first['id']) ?? -1);
                        final bestFarmerName = actionableOffers.isEmpty
                          ? 'supplier'
                          : (actionableOffers.first['farmerName'] ?? 'supplier').toString();

                        final accepted = offers.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'accepted').toList();
                        final status = (request['status'] ?? 'open').toString();
                        final isOpen = status.toLowerCase() == 'open';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 14, color: widget.primaryGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      request['productName'].toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: widget.textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(color: widget.textLight, fontSize: 12),
                                  children: [
                                    TextSpan(text: '${request['quantity']} ${request['unit']} • '),
                                    TextSpan(
                                      text: status.replaceAll('_', ' '),
                                      style: TextStyle(
                                        color: isOpen ? widget.primaryGreen : widget.textLight,
                                        fontWeight: isOpen ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (actionableOffers.isNotEmpty)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.trending_down, size: 14, color: widget.primaryGreen),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Best: ${actionableOffers.first['pricePerUnit']} MAD from $bestFarmerName',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: widget.primaryGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const Spacer(),
                              if (accepted.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: widget.primaryGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.verified_outlined, size: 14, color: widget.primaryGreen),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Accepted: ${accepted.first['farmerName']}',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: widget.primaryGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (accepted.isEmpty && actionableOffers.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.hourglass_top_rounded, size: 14, color: widget.textLight),
                                      const SizedBox(width: 6),
                                      const Flexible(
                                        child: Text(
                                          'Waiting for farmer offers',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (accepted.isEmpty && actionableOffers.isNotEmpty)
                                ElevatedButton(
                                  onPressed: actionableOffers.isEmpty || requestId == -1 || bestOfferId == -1
                                      ? null
                                      : () {
                                          if (actionableOffers.length == 1) {
                                            _acceptOffer(requestId, bestOfferId);
                                            return;
                                          }
                                          _openOfferSelectionSheet(requestId, actionableOffers);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.primaryGreen,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 38),
                                  ),
                                  child: Text(
                                    actionableOffers.length <= 1
                                        ? 'Accept $bestFarmerName'
                                        : 'Choose Offer (${actionableOffers.length})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionPill(String label, int section) {
    final selected = _activeSection == section;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeSection = section),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? widget.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? widget.primaryGreen : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : widget.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
            builder: (context) => ProductDetailScreen(
              product: p,
              buyerType: widget.buyerType,
            ),
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
                    if (img.startsWith('data:image')) {
                      final base64Str = img.split(',').last;
                      return Image.memory(
                        base64Decode(base64Str),
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 130,
                          color: const Color(0xFFF1F4F1),
                          child: const Icon(Icons.image_not_supported_outlined,
                              size: 40, color: Colors.grey),
                        ),
                      );
                    }
                    if (img.startsWith('http')) {
                      return Image.network(
                        img,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 130,
                          color: const Color(0xFFF1F4F1),
                          child: const Icon(Icons.image_not_supported_outlined,
                              size: 40, color: Colors.grey),
                        ),
                      );
                    }
                    return Image.asset(
                      img,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 130,
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
                                  builder: (context) => ProductDetailScreen(
                                    product: p,
                                    buyerType: widget.buyerType,
                                  ),
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
                      Text('0 MAD',
                          style: TextStyle(
                              color: widget.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text('Up to ${_maxPrice.toInt()} MAD',
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
                          activeThumbColor: widget.primaryGreen,
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

  void _handleOrder(Map<String, dynamic> product) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OrderProcessingDialog(
        productName: product['name'] as String,
        primaryGreen: widget.primaryGreen,
      ),
    );

    try {
      final user = await SessionService.getUser();
      if (user == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please log in again.')),
          );
        }
        return;
      }

      final availableQty = (product['quantity'] as num?)?.toInt() ?? 0;
      if (availableQty <= 0) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This product is out of stock.')),
          );
        }
        return;
      }

      await ApiService.createOrder({
        'buyerId': user.id,
        'buyerName': user.fullName,
        'buyerType': widget.buyerType.toLowerCase(),
        'farmerId': product['farmerId'],
        'farmerName': product['farmerName'] ?? '',
        'items': [
          {
            'productId': product['id'],
            'productName': product['name'],
            'unitPrice': product['priceValue'] ?? product['price'],
            'quantity': 1,
            'unit': product['unit'] ?? 'Kg',
          }
        ],
        'totalAmount': (product['priceValue'] ?? product['price'] ?? 0) as num,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSheet(product);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order')),
        );
      }
    }
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
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────
//  ANIMATED LIVE NETWORK CARD
// ─────────────────────────────────────────────────────────
class LiveNetworkCard extends StatefulWidget {
  final bool loading;
  final int totalShipments;
  final int inTransitShipments;
  final int pendingOrders;

  const LiveNetworkCard({
    super.key,
    required this.loading,
    required this.totalShipments,
    required this.inTransitShipments,
    required this.pendingOrders,
  });

  @override
  State<LiveNetworkCard> createState() => _LiveNetworkCardState();
}

class _LiveNetworkCardState extends State<LiveNetworkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int get _liveScore {
    if (widget.loading) return 0;
    return widget.inTransitShipments + widget.pendingOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
          color: const Color(0xFF0F3628),
          borderRadius: BorderRadius.circular(28),

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
                              Text('Real data snapshot for your buyer activity',
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
                            const Text('SNAPSHOT',
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
                            widget.loading ? '...' : '$_liveScore',
                            key: ValueKey<int>(_liveScore),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.loading
                              ? 'Loading real data...'
                              : '${widget.pendingOrders} pending orders • ${widget.inTransitShipments} in transit • ${widget.totalShipments} total shipments',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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

class _CreateShipmentSheet extends StatefulWidget {
  final int? buyerId;
  final String buyerType;
  final VoidCallback? onCreated;
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  const _CreateShipmentSheet({
    super.key,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
    this.buyerId,
    this.buyerType = 'restaurant',
    this.onCreated,
  });

  @override
  State<_CreateShipmentSheet> createState() => _CreateShipmentSheetState();
}

class _CreateShipmentSheetState extends State<_CreateShipmentSheet> {
  late final TextEditingController _weightCtrl;
  String? _selectedOrigin;
  String? _selectedDestination;
  int _packageCount = 1;
  bool _submitting = false;

  static const List<String> _locations = [
    'Agadir',
    'Casablanca',
    'Rabat',
    'Marrakech',
    'Fes',
    'Meknes',
    'Tangier',
    'Oujda',
  ];

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final origin = _selectedOrigin;
    final destination = _selectedDestination;
    final weight = double.tryParse(_weightCtrl.text.trim());

    if (origin == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and delivery locations')),
      );
      return;
    }

    if (origin == destination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and delivery locations must be different')),
      );
      return;
    }

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight must be greater than 0')),
      );
      return;
    }

    if (_packageCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Packages must be at least 1')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.createShipment({
        'orderId': null,
        'buyerId': widget.buyerId,
        'buyerType': widget.buyerType.toLowerCase(),
        'pickupLocation': origin,
        'deliveryLocation': destination,
        'weight': weight,
        'containerCount': _packageCount,
        'status': 'requested',
        'estimatedDeliveryDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Shipment initiated successfully!'),
          backgroundColor: widget.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create shipment')),
      );
    }
  }

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
              color: widget.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter the shipment details to initiate the logistics flow.",
            style: TextStyle(fontSize: 14, color: widget.textLight),
          ),
          const SizedBox(height: 32),
          _sectionTitle('Location', Icons.place_outlined),
          const SizedBox(height: 12),
          _locationDropdown(
            label: 'Origin / Port of Loading',
            hint: 'Select pickup location',
            icon: Icons.location_on_outlined,
            value: _selectedOrigin,
            onChanged: (value) => setState(() => _selectedOrigin = value),
          ),
          const SizedBox(height: 12),
          _locationDropdown(
            label: 'Destination / Port of Discharge',
            hint: 'Select delivery location',
            icon: Icons.flag_outlined,
            value: _selectedDestination,
            onChanged: (value) => setState(() => _selectedDestination = value),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Cargo Details', Icons.inventory_2_outlined),
          const SizedBox(height: 12),
          _inputShell(
            child: TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Total Weight',
                hintText: 'Enter weight in kg',
                prefixIcon: const Icon(Icons.scale_outlined),
                suffixText: 'kg',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintStyle: TextStyle(color: widget.textLight, fontSize: 13),
                labelStyle: TextStyle(color: widget.textLight, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _inputShell(
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: widget.textLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Number of Packages',
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _stepperButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (_packageCount > 1) {
                      setState(() => _packageCount--);
                    }
                  },
                ),
                Container(
                  width: 36,
                  alignment: Alignment.center,
                  child: Text(
                    '$_packageCount',
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _stepperButton(
                  icon: Icons.add,
                  onTap: () => setState(() => _packageCount++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: widget.primaryGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Initiate Shipment",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: widget.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: widget.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _inputShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _locationDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFFF2F7F3),
      ),
      child: _inputShell(
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 280,
          dropdownColor: const Color(0xFFF2F7F3),
          borderRadius: BorderRadius.circular(16),
          style: TextStyle(
            color: widget.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          iconEnabledColor: widget.primaryGreen,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: widget.primaryGreen),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hintStyle: TextStyle(color: widget.textLight, fontSize: 13),
            labelStyle: TextStyle(color: widget.textLight, fontSize: 13),
          ),
          items: _locations
              .map(
                (loc) => DropdownMenuItem<String>(
                  value: loc,
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: widget.primaryGreen,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        loc,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 16, color: widget.textColor),
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

  const _OrderSuccessSheet({
    required this.product,
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
          SizedBox(
            width: double.infinity,
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
  final String buyerType;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.buyerType = 'restaurant',
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  Map<String, dynamic>? _farmer;

  static const Color primaryGreen = Color(0xFF23763D);
  static const Color bgColor = Color(0xFFF1F8F1);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1A1D1A);
  static const Color textLight = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _loadFarmer();
  }

  Future<void> _loadFarmer() async {
    try {
      final farmerId = widget.product['farmerId'];
      if (farmerId != null) {
        final data = await ApiService.getUserById(farmerId is int ? farmerId : int.parse(farmerId.toString()));
        if (mounted) setState(() => _farmer = data);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final String farmerName = _farmer?['fullName']?.toString() ??
        p['farmerName']?.toString() ?? 'Farmer';
    final String farmerCity = _farmer?['city']?.toString() ?? '';
    final String farmerType = _farmer?['farmingType']?.toString() ?? '';
    final String farmerPhone = _farmer?['phone']?.toString() ?? '';
    final String name = p['name'] ?? 'Organic Product';
    final String priceDisplay =
        '${p['price'] ?? 0} MAD';
    final String unit = p['unit']?.toString() ?? 'unit';
    final String image = p['image'] ?? 'assets/images/usine/avocado.jpg';
    final String origin = p['location']?.toString() ?? p['origin']?.toString() ?? 'Local Farm';
    final bool isOrganic = p['isOrganic'] == true;
    final bool isAvailable = p['isAvailable'] != false;
    final int quantity = (p['quantity'] as num?)?.toInt() ?? 0;
    final bool inStock = isAvailable && quantity > 0;

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
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section with Gradient Overlay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
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
                                Colors.black.withValues(alpha: 0.05),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.2),
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
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
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
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.4,
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
                                ? Colors.red.withValues(alpha: 0.1)
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
                        priceDisplay,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ $unit',
                        style: const TextStyle(
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
                          color: inStock
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: (inStock ? primaryGreen : Colors.red)
                                  .withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              inStock
                                  ? Icons.bolt_rounded
                                  : Icons.remove_circle_outline,
                              size: 16,
                              color: inStock ? primaryGreen : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              inStock ? 'IN STOCK' : 'OUT OF STOCK',
                              style: TextStyle(
                                color: inStock ? primaryGreen : Colors.red,
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      p['description']?.toString().isNotEmpty == true
                          ? p['description'].toString()
                          : 'Hand-picked fresh produce directly from the farm. Grown with care and delivered to your door.',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.75),
                        fontSize: 13,
                        height: 1.55,
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
                          color: primaryGreen.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                primaryGreen.withValues(alpha: 0.15),
                            child: const Icon(Icons.person,
                                size: 28, color: primaryGreen),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRODUCED BY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: textLight,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                farmerName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                              if (farmerCity.isNotEmpty || farmerType.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    [if (farmerType.isNotEmpty) farmerType, if (farmerCity.isNotEmpty) farmerCity].join(' • '),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: textLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (farmerPhone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    farmerPhone,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: textLight,
                                    ),
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
                              color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_rounded,
                                    size: 18, color: Color(0xFF1565C0)),
                                SizedBox(height: 4),
                                Text(
                                  'Contact\nFarmer',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1565C0),
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
                            '24 – 48 Hours',
                            color: const Color(0xFFE65100)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                            Icons.location_on_rounded, 'ORIGIN', origin,
                            color: const Color(0xFF1565C0)),
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
                          color: Colors.grey.withValues(alpha: 0.2),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatCards(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final p = widget.product;
    final qty = p['quantity']?.toString() ?? 'N/A';
    final unit = p['unit']?.toString() ?? '';
    final bool isOrganic = p['isOrganic'] == true;
    final bool isUrgent = p['isUrgent'] == true;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildStatCard(
            qty,
            'QUANTITY',
            '$qty $unit available',
            accentColor: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            isOrganic ? 'YES' : 'NO',
            'ORGANIC',
            isOrganic ? 'Certified organic' : 'Conventional',
            accentColor: const Color(0xFF880E4F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            isUrgent ? 'HOT' : 'STD',
            'DEMAND',
            isUrgent ? 'High demand' : 'Standard',
            accentColor: const Color(0xFF006064),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value,
      {Color color = primaryGreen}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: textLight,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: textLight,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openFarmerChat(BuildContext context) async {
    final user = await SessionService.getUser();
    if (!context.mounted) return;
    final product = widget.product;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IntegratedFarmerChatSheet(
        farmerName: product['farmerName'] ?? 'Farmer',
        farmerId: product['farmerId'] ?? 1,
        currentUserId: user?.id ?? 0,
        currentUserName: user?.fullName ?? '',
      ),
    );
  }
}

class _IntegratedFarmerChatSheet extends StatefulWidget {
  final String farmerName;
  final int farmerId;
  final int currentUserId;
  final String currentUserName;

  const _IntegratedFarmerChatSheet({
    required this.farmerName,
    required this.farmerId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<_IntegratedFarmerChatSheet> createState() => _IntegratedFarmerChatSheetState();
}

class _IntegratedFarmerChatSheetState extends State<_IntegratedFarmerChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final all = await ApiService.getMessages(
        senderId: '${widget.currentUserId}',
        receiverId: '${widget.farmerId}',
      );
      // Also get reverse direction
      final reverse = await ApiService.getMessages(
        senderId: '${widget.farmerId}',
        receiverId: '${widget.currentUserId}',
      );
      final combined = [...all.cast<Map<String, dynamic>>(), ...reverse.cast<Map<String, dynamic>>()];
      combined.sort((a, b) => (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? ''));
      if (mounted) {
        setState(() {
          _messages = combined;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    try {
      await ApiService.sendMessage({
        'senderId': widget.currentUserId,
        'senderName': widget.currentUserName,
        'receiverId': widget.farmerId,
        'receiverName': widget.farmerName,
        'content': text,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      _loadMessages();
    } catch (_) {}
  }

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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF23763D),
                  child: Text(
                    widget.farmerName.isNotEmpty ? widget.farmerName[0] : 'F',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.farmerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Online',
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hello!'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == widget.currentUserId;
                          return _buildMessage(msg['content'] ?? '', isMe: isMe);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF23763D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
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
                    color: primaryGreen.withValues(alpha: 0.05),
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
                    color: Colors.black.withValues(alpha: 0.02),
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
                                      color: Colors.black.withValues(alpha: 0.1),
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
                color: primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(35),
      
                border:
                    Border.all(color: primaryGreen.withValues(alpha: 0.1)),
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
                          color: Colors.green.withValues(alpha: 0.3),
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
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
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
              color: Colors.black.withValues(alpha: 0.02), blurRadius: 20),
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
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5), 16, dotOuterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

