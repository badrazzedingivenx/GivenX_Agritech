import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order.dart';
import '../../../viewmodels/admin_stats_viewmodel.dart';

/// Platform-wide KPI dashboard for the admin: users per role, total orders,
/// shipments and finance requests, sourced from /users, /orders, /shipments
/// and /financeRequests.
class AdminStatisticsScreen extends StatelessWidget {
  static const routeName = '/admin/statistics';
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminStatsViewModel>(
      create: (_) => AdminStatsViewModel()..load(),
      child: const _AdminStatisticsContent(),
    );
  }
}

class _AdminStatisticsContent extends StatelessWidget {
  const _AdminStatisticsContent();

  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _textColor = Color(0xFF1A1D1A);
  static const Color _textLight = Color(0xFF757575);
  static const Color _bg = Color(0xFFF4F9F3);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminStatsViewModel>();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _textColor,
        title: const Text('Statistics',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(vm.error!, style: const TextStyle(color: _textLight)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: vm.load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: vm.load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Users by Role'),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _kpiCard('Agriculteurs', '${vm.farmerCount}',
                                  Icons.agriculture_outlined,
                                  const Color(0xFF2E7D32)),
                              _kpiCard('Acheteurs', '${vm.buyerCount}',
                                  Icons.storefront_outlined,
                                  const Color(0xFF1565C0)),
                              _kpiCard('Transporteurs', '${vm.transporterCount}',
                                  Icons.local_shipping_outlined,
                                  const Color(0xFFE65100)),
                              _kpiCard('Ét. financement', '${vm.bankCount}',
                                  Icons.account_balance_outlined,
                                  const Color(0xFF6A1B9A)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _sectionLabel('Platform Activity'),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _kpiCard('Total Users', '${vm.totalUsers}',
                                  Icons.people_outline,
                                  const Color(0xFF1565C0)),
                              _kpiCard('Total Orders', '${vm.totalOrders}',
                                  Icons.receipt_long_outlined,
                                  const Color(0xFFE65100)),
                              _kpiCard('Shipments', '${vm.totalShipments}',
                                  Icons.local_shipping_outlined,
                                  const Color(0xFF00838F)),
                              _kpiCard(
                                  'Finance Req.',
                                  '${vm.totalFinanceRequests}',
                                  Icons.request_quote_outlined,
                                  const Color(0xFF6A1B9A)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _sectionLabel('Pending Validation'),
                          const SizedBox(height: 12),
                          _wideStat(
                            'Accounts awaiting approval',
                            '${vm.pendingUsers}',
                            Icons.how_to_reg_outlined,
                            const Color(0xFFE65100),
                          ),
                          const SizedBox(height: 12),
                          _wideStat(
                            'Delivered revenue',
                            '${vm.totalRevenue.toStringAsFixed(0)} MAD',
                            Icons.account_balance_wallet_outlined,
                            _primaryGreen,
                          ),
                          const SizedBox(height: 24),
                          _sectionLabel('Orders by Status'),
                          const SizedBox(height: 12),
                          _orderStatusRow(vm),
                          const SizedBox(height: 24),
                        ]),
                  ),
                ),
    );
  }

  Widget _orderStatusRow(AdminStatsViewModel vm) {
    Widget mini(String label, OrderStatus status, Color color) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text('${vm.orderCountByStatus(status)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        );
    return Row(children: [
      mini('Pending', OrderStatus.pending, Colors.amber.shade800),
      mini('Transit', OrderStatus.inTransit, const Color(0xFFE65100)),
      mini('Delivered', OrderStatus.delivered, const Color(0xFF2E7D32)),
      mini('Cancelled', OrderStatus.cancelled, Colors.red),
    ]);
  }

  Widget _kpiCard(String title, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: accent, size: 22),
        ),
        const Spacer(),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _textColor)),
        const SizedBox(height: 2),
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _textLight, fontSize: 12)),
      ]),
    );
  }

  Widget _wideStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    color: _textColor,
                    fontWeight: FontWeight.w600))),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800, color: _textColor));
}
