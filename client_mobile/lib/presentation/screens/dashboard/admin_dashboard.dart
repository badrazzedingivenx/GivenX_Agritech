import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/product.dart';
import '../../../models/order.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _textColor = Color(0xFF1A1D1A);
  static const Color _textLight = Color(0xFF757575);

  int _currentIndex = 0;
  int? _currentUserId;

  int _userCount = 0;
  int _productCount = 0;
  int _orderCount = 0;
  double _totalRevenue = 0;
  bool _loading = true;

  List<User> _users = [];
  List<Product> _products = [];
  List<Order> _orders = [];

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
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final user = await SessionService.getUser();
      _currentUserId = user?.id;
      final results = await Future.wait([
        ApiService.getUsers(),
        ApiService.getProducts(),
        ApiService.getOrders(),
      ]);
      if (mounted) {
        final users = (results[0] as List)
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
        final products = (results[1] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        final orders = (results[2] as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _users = users;
          _products = products;
          _orders = orders;
          _userCount = users.length;
          _productCount = products.length;
          _orderCount = orders.length;
          _totalRevenue = orders
              .where((o) => o.status == OrderStatus.delivered)
              .fold(0.0, (sum, o) => sum + o.totalAmount);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await SessionService.clearSession();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: _currentIndex,
      userRole: 'admin',
      userId: _currentUserId,
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.people_outline, label: 'Users'),
        NavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
        NavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      onTabSelected: (index) => setState(() => _currentIndex = index),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildUsersTab(),
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final farmers = _users.where((u) => u.role == UserRole.farmer).length;
    final buyers = _users.where((u) => u.role == UserRole.buyer).length;
    final transporters = _users.where((u) => u.role == UserRole.transporter).length;
    final pendingOrders = _orders.where((o) => o.status == OrderStatus.pending).length;
    final inTransitOrders = _orders.where((o) => o.status == OrderStatus.inTransit).length;
    final deliveredOrders = _orders.where((o) => o.status == OrderStatus.delivered).length;
    final cancelledOrders = _orders.where((o) => o.status == OrderStatus.cancelled).length;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ADMIN DASHBOARD',
                style: TextStyle(color: _primaryGreen, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text('Platform Overview',
                style: TextStyle(fontSize: 28, color: _textColor, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Here is the status of all platform activity.', style: TextStyle(color: _textLight, fontSize: 13)),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              GridView.count(
                crossAxisCount: _gridColumns(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: _gridAspectRatio(context),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _statCard('Total Users', '$_userCount', Icons.people_outline, const Color(0xFF1565C0)),
                  _statCard('Products', '$_productCount', Icons.inventory_2_outlined, _primaryGreen),
                  _statCard('Orders', '$_orderCount', Icons.receipt_long_outlined, const Color(0xFFE65100)),
                  _statCard('Revenue', '${_totalRevenue.toStringAsFixed(0)} MAD', Icons.account_balance_wallet_outlined, const Color(0xFF6A1B9A)),
                ],
              ),
            const SizedBox(height: 28),
            _sectionLabel('User Distribution'),
            const SizedBox(height: 12),
            _roleBar('Farmers', farmers, _userCount, const Color(0xFF2E7D32)),
            const SizedBox(height: 8),
            _roleBar('Buyers', buyers, _userCount, const Color(0xFF1565C0)),
            const SizedBox(height: 8),
            _roleBar('Transporters', transporters, _userCount, const Color(0xFFE65100)),
            const SizedBox(height: 28),
            _sectionLabel('Order Status'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _miniStat('Pending', pendingOrders, Colors.amber)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('In Transit', inTransitOrders, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('Delivered', deliveredOrders, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('Cancelled', cancelledOrders, Colors.red)),
            ]),
            const SizedBox(height: 28),
            _sectionLabel('Recent Orders'),
            const SizedBox(height: 12),
            ..._orders.take(5).map(_orderTile),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1D1A))),
          const SizedBox(height: 4),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _roleBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, color: color, backgroundColor: color.withValues(alpha: 0.1), minHeight: 6),
          ),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textColor));
  }

  Widget _buildUsersTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F3),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ADMIN DASHBOARD',
                          style: TextStyle(color: _primaryGreen, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text('Users',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textColor, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('${_users.length} registered users on the platform.',
                          style: TextStyle(fontSize: 13, color: _textLight)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _userTile(_users[i])),
                      childCount: _users.length,
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _userTile(User user) {
    final color = _roleColor(user.role);
    return GestureDetector(
      onTap: () => _showUserDetail(user),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                user.fullName.isNotEmpty ? user.fullName : user.email,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textColor),
              ),
              const SizedBox(height: 3),
              Text(
                '${user.email}${user.city.isNotEmpty ? ' · ${user.city}' : ''}',
                style: TextStyle(fontSize: 12, color: _textLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(user.role.name.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          ),
        ]),
      ),
    );
  }

  void _showUserDetail(User user) {
    final color = _roleColor(user.role);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 36,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.fullName.isNotEmpty ? user.fullName : user.email,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textColor)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(user.role.name.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 20),
          _detailRow(Icons.email_outlined, const Color(0xFFE65100), 'Email', user.email),
          if (user.phone.isNotEmpty)
            _detailRow(Icons.phone_outlined, const Color(0xFFAD1457), 'Phone', user.phone),
          if (user.city.isNotEmpty)
            _detailRow(Icons.location_on_outlined, const Color(0xFF6A1B9A), 'City', user.city),
          if (user.companyName != null && user.companyName!.isNotEmpty)
            _detailRow(Icons.business_outlined, const Color(0xFF1565C0), 'Company', user.companyName!),
          if (user.farmingType != null && user.farmingType!.isNotEmpty)
            _detailRow(Icons.eco_outlined, _primaryGreen, 'Farming Type', user.farmingType!),
          if (user.vehicleType != null && user.vehicleType!.isNotEmpty)
            _detailRow(Icons.local_shipping_outlined, const Color(0xFFE65100), 'Vehicle',
                '${user.vehicleType} (${user.capacity ?? ''})'),
          if (user.bankName != null && user.bankName!.isNotEmpty)
            _detailRow(Icons.account_balance_outlined, const Color(0xFF1565C0), 'Bank', user.bankName!),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textColor)),
        ]),
      ]),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.farmer: return const Color(0xFF2E7D32);
      case UserRole.buyer: return const Color(0xFF1565C0);
      case UserRole.transporter: return const Color(0xFFE65100);
      case UserRole.bank: return const Color(0xFF6A1B9A);
      case UserRole.admin: return Colors.red;
    }
  }

  Widget _buildProductsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F3),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ADMIN DASHBOARD',
                          style: TextStyle(color: _primaryGreen, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text('Products',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textColor, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('${_products.length} products listed on the platform.',
                          style: TextStyle(fontSize: 13, color: _textLight)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _productTile(_products[i])),
                      childCount: _products.length,
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _productTile(Product p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.eco_outlined, color: _primaryGreen, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textColor)),
            const SizedBox(height: 3),
            Text('${p.farmerName} · ${p.location} · ${p.quantity} ${p.unit}',
                style: TextStyle(fontSize: 12, color: _textLight),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${p.price.toStringAsFixed(0)} MAD',
              style: TextStyle(fontWeight: FontWeight.w800, color: _primaryGreen, fontSize: 14)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(p.category.name,
                style: TextStyle(fontSize: 10, color: _primaryGreen, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildOrdersTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F3),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ADMIN DASHBOARD',
                          style: TextStyle(color: _primaryGreen, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text('Orders',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textColor, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('${_orders.length} orders placed on the platform.',
                          style: TextStyle(fontSize: 13, color: _textLight)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _orderTile(_orders[i])),
                      childCount: _orders.length,
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _orderTile(Order order) {
    final color = _orderStatusColor(order.status);
    final items = order.items
        .map((i) => '${i.quantity.toStringAsFixed(0)} ${i.unit} ${i.productName}')
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('#ORD-${order.id}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _textColor))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(order.status.label.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(items, style: TextStyle(fontSize: 12, color: _textLight), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.person_outline, size: 14, color: _textLight),
          const SizedBox(width: 4),
          Text(order.buyerName, style: TextStyle(fontSize: 12, color: _textColor)),
          const Spacer(),
          Icon(Icons.agriculture_outlined, size: 14, color: _textLight),
          const SizedBox(width: 4),
          Text(order.farmerName, style: TextStyle(fontSize: 12, color: _textColor)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.payments_outlined, size: 14, color: _primaryGreen),
          const SizedBox(width: 4),
          Text('${order.totalAmount.toStringAsFixed(2)} MAD',
              style: TextStyle(fontWeight: FontWeight.w800, color: _primaryGreen, fontSize: 13)),
        ]),
      ]),
    );
  }

  Color _orderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.amber;
      case OrderStatus.confirmed: return Colors.teal;
      case OrderStatus.processing: return Colors.blue;
      case OrderStatus.inTransit: return const Color(0xFFE65100);
      case OrderStatus.delivered: return const Color(0xFF2E7D32);
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.admin_panel_settings, color: Colors.red, size: 36),
            ),
            const SizedBox(height: 14),
            Text('Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textColor)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('ADMINISTRATOR',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            _profileInfoRow(Icons.people_outline, const Color(0xFF1565C0), 'Total Users', '$_userCount users'),
            _divider(),
            _profileInfoRow(Icons.inventory_2_outlined, _primaryGreen, 'Total Products', '$_productCount products'),
            _divider(),
            _profileInfoRow(Icons.receipt_long_outlined, const Color(0xFFE65100), 'Total Orders', '$_orderCount orders'),
            _divider(),
            _profileInfoRow(Icons.account_balance_wallet_outlined, const Color(0xFF6A1B9A), 'Total Revenue',
                '${_totalRevenue.toStringAsFixed(0)} MAD'),
          ]),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _logout,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('Log Out', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _profileInfoRow(IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: _textLight, fontWeight: FontWeight.w500))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textColor)),
      ]),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade100);
}
