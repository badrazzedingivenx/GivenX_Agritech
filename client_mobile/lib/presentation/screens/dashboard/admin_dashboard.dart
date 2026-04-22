import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/product.dart';
import '../../../models/order.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF1B5E20);
  static const Color _bg = Color(0xFFF4F9F3);

  late TabController _tabCtrl;
  int _userCount = 0;
  int _productCount = 0;
  int _orderCount = 0;
  double _totalRevenue = 0;
  bool _loading = true;

  List<User> _users = [];
  List<Product> _products = [];
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getUsers(),
        ApiService.getProducts(),
        ApiService.getOrders(),
      ]);
      if (mounted) {
        final users = (results[0] as List).map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
        final products = (results[1] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        final orders = (results[2] as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
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
    } catch (e) {
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 10),
            Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.inventory), text: 'Products'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildOverview(),
                _buildUsers(),
                _buildProducts(),
                _buildOrders(),
              ],
            ),
    );
  }

  // ─── OVERVIEW TAB ───────────────────────────────────────

  Widget _buildOverview() {
    final farmers = _users.where((u) => u.role == UserRole.farmer).length;
    final buyers = _users.where((u) => u.role == UserRole.buyer).length;
    final transporters = _users.where((u) => u.role == UserRole.transporter).length;
    final pendingOrders = _orders.where((o) => o.status == OrderStatus.pending).length;
    final deliveredOrders = _orders.where((o) => o.status == OrderStatus.delivered).length;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats grid
          Row(
            children: [
              Expanded(child: _statCard('Total Users', '$_userCount', Icons.people, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Products', '$_productCount', Icons.inventory_2, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Orders', '$_orderCount', Icons.receipt, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Revenue', '${_totalRevenue.toStringAsFixed(0)} MAD', Icons.attach_money, const Color(0xFF1B5E20))),
            ],
          ),
          const SizedBox(height: 24),

          // Role breakdown
          _sectionTitle('User Distribution'),
          const SizedBox(height: 12),
          _roleBar('Farmers', farmers, _userCount, Colors.green),
          const SizedBox(height: 8),
          _roleBar('Buyers', buyers, _userCount, Colors.blue),
          const SizedBox(height: 8),
          _roleBar('Transporters', transporters, _userCount, Colors.orange),
          const SizedBox(height: 24),

          // Order status breakdown
          _sectionTitle('Order Status'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Pending', pendingOrders, Colors.amber)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('In Transit', _orders.where((o) => o.status == OrderStatus.inTransit).length, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('Delivered', deliveredOrders, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('Cancelled', _orders.where((o) => o.status == OrderStatus.cancelled).length, Colors.red)),
            ],
          ),
          const SizedBox(height: 24),

          // Recent orders
          _sectionTitle('Recent Orders'),
          const SizedBox(height: 12),
          ..._orders.take(5).map(_orderTile),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _roleBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)));
  }

  // ─── USERS TAB ──────────────────────────────────────────

  Widget _buildUsers() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        itemBuilder: (_, i) {
          final user = _users[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: _roleColor(user.role).withOpacity(0.15),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _roleColor(user.role)),
                ),
              ),
              title: Text(user.fullName.isNotEmpty ? user.fullName : user.email, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${user.email} • ${user.city}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _roleColor(user.role).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role.name.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _roleColor(user.role)),
                ),
              ),
              onTap: () => _showUserDetail(user),
            ),
          );
        },
      ),
    );
  }

  void _showUserDetail(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 36,
                backgroundColor: _roleColor(user.role).withOpacity(0.15),
                child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _roleColor(user.role))),
              ),
              const SizedBox(height: 12),
              Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: _roleColor(user.role).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(user.role.name.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _roleColor(user.role))),
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.email, 'Email', user.email),
              _detailRow(Icons.phone, 'Phone', user.phone),
              _detailRow(Icons.location_city, 'City', user.city),
              if (user.companyName != null && user.companyName!.isNotEmpty)
                _detailRow(Icons.business, 'Company', user.companyName!),
              if (user.farmingType != null && user.farmingType!.isNotEmpty)
                _detailRow(Icons.eco, 'Farming Type', user.farmingType!),
              if (user.vehicleType != null && user.vehicleType!.isNotEmpty)
                _detailRow(Icons.local_shipping, 'Vehicle', '${user.vehicleType} (${user.capacity ?? ''})'),
              if (user.bankName != null && user.bankName!.isNotEmpty)
                _detailRow(Icons.account_balance, 'Bank', user.bankName!),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _primary),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.farmer: return Colors.green;
      case UserRole.buyer: return Colors.blue;
      case UserRole.transporter: return Colors.orange;
      case UserRole.bank: return Colors.purple;
      case UserRole.admin: return Colors.red;
    }
  }

  // ─── PRODUCTS TAB ───────────────────────────────────────

  Widget _buildProducts() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        itemBuilder: (_, i) {
          final p = _products[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco, color: Color(0xFF1B5E20)),
              ),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${p.farmerName} • ${p.location} • ${p.quantity} ${p.unit}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${p.price.toStringAsFixed(0)} MAD',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 2),
                  Text(p.category.name, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── ORDERS TAB ─────────────────────────────────────────

  Widget _buildOrders() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _orderTile(_orders[i]),
      ),
    );
  }

  Widget _orderTile(Order order) {
    final color = _orderStatusColor(order.status);
    final items = order.items.map((i) => '${i.quantity.toStringAsFixed(0)} ${i.unit} ${i.productName}').join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('#ORD-${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(order.status.label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(items, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(order.buyerName, style: const TextStyle(fontSize: 12)),
              const Spacer(),
              const Icon(Icons.agriculture, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(order.farmerName, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 14, color: Color(0xFF1B5E20)),
              Text('${order.totalAmount.toStringAsFixed(2)} MAD',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Color _orderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.amber;
      case OrderStatus.confirmed: return Colors.teal;
      case OrderStatus.processing: return Colors.blue;
      case OrderStatus.inTransit: return Colors.orange;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }
}
