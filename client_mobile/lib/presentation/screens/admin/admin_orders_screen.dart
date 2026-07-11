import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order.dart';
import '../../../viewmodels/admin_orders_viewmodel.dart';

/// Admin orders supervision: lists every order across all users, shows buyer
/// and agriculteur names, status and amount, and lets the admin override a
/// stuck order's status.
class AdminOrdersScreen extends StatelessWidget {
  static const routeName = '/admin/orders';
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminOrdersViewModel>(
      create: (_) => AdminOrdersViewModel()..load(),
      child: const _AdminOrdersContent(),
    );
  }
}

class _AdminOrdersContent extends StatelessWidget {
  const _AdminOrdersContent();

  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _textColor = Color(0xFF1A1D1A);
  static const Color _textLight = Color(0xFF757575);
  static const Color _bg = Color(0xFFF4F9F3);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminOrdersViewModel>();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _textColor,
        title: const Text('Orders Supervision',
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
                  child: CustomScrollView(slivers: [
                    SliverToBoxAdapter(child: _filters(vm)),
                    if (vm.orders.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Text('No orders in this category',
                                style: TextStyle(color: _textLight))),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _orderTile(context, vm, vm.orders[i]),
                            ),
                            childCount: vm.orders.length,
                          ),
                        ),
                      ),
                  ]),
                ),
    );
  }

  Widget _filters(AdminOrdersViewModel vm) {
    final statuses = [null, ...OrderStatus.values];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${vm.totalCount} orders on the platform',
            style: const TextStyle(fontSize: 13, color: _textLight)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statuses.map((s) {
              final selected = vm.statusFilter == s;
              final label = s == null ? 'All' : s.label;
              final count = s == null ? vm.totalCount : vm.countFor(s);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => vm.setFilter(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? _primaryGreen
                              : Colors.grey.shade200),
                    ),
                    child: Text('$label ($count)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : _textColor)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _orderTile(
      BuildContext context, AdminOrdersViewModel vm, Order order) {
    final color = _statusColor(order.status);
    final isUpdating = order.id != null && vm.updating.contains(order.id);
    final items = order.items
        .map((i) => '${i.quantity.toStringAsFixed(0)} ${i.unit} ${i.productName}')
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('#ORD-${order.id}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _textColor))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Text(order.status.label.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ]),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(items,
              style: const TextStyle(fontSize: 12, color: _textLight),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.person_outline, size: 14, color: _textLight),
          const SizedBox(width: 4),
          Expanded(
              child: Text(order.buyerName,
                  style: const TextStyle(fontSize: 12, color: _textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          Icon(Icons.agriculture_outlined, size: 14, color: _textLight),
          const SizedBox(width: 4),
          Expanded(
              child: Text(order.farmerName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: _textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.payments_outlined, size: 14, color: _primaryGreen),
          const SizedBox(width: 4),
          Text('${order.totalAmount.toStringAsFixed(2)} MAD',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _primaryGreen,
                  fontSize: 13)),
          const Spacer(),
          if (isUpdating)
            const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            TextButton.icon(
              onPressed: () => _showStatusSheet(context, vm, order),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Status',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ]),
      ]),
    );
  }

  void _showStatusSheet(
      BuildContext context, AdminOrdersViewModel vm, Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Override status · #ORD-${order.id}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textColor)),
            const SizedBox(height: 16),
            ...OrderStatus.values.map((s) {
              final selected = s == order.status;
              final color = _statusColor(s);
              return ListTile(
                leading: Icon(Icons.circle, size: 14, color: color),
                title: Text(s.label,
                    style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        color: _textColor)),
                trailing: selected
                    ? const Icon(Icons.check, color: _primaryGreen)
                    : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (selected) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await vm.updateStatus(order, s);
                  messenger.showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Order #ORD-${order.id} → ${s.label}'
                        : 'Update failed. Try again.'),
                    backgroundColor: ok ? _primaryGreen : Colors.red,
                  ));
                },
              );
            }),
          ]),
        ),
      ),
    );
  }

  static Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.amber.shade800;
      case OrderStatus.confirmed:
        return Colors.teal;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.inTransit:
        return const Color(0xFFE65100);
      case OrderStatus.delivered:
        return const Color(0xFF2E7D32);
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
