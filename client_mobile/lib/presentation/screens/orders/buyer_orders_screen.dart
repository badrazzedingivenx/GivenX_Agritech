import 'package:flutter/material.dart';

import '../../../models/order.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../chat/chat_screen.dart';
import '../shipments/create_shipment_screen.dart';

/// Buyer-facing list of procurement orders, filtered by the connected buyer.
///
/// GET /orders?buyerId={currentUser.id}
///
/// A CONFIRMED order can be tapped to open a detail sheet exposing the farmer
/// contact, a chat shortcut, and a transport request shortcut.
class BuyerOrdersScreen extends StatefulWidget {
  static const routeName = '/buyer-orders';

  /// Optional restriction to a single buyer type ('restaurant' | 'industry').
  final String? buyerType;

  const BuyerOrdersScreen({super.key, this.buyerType});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  static const Color _primaryGreen = Color(0xFF23763D);

  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  int? _currentUserId;
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await SessionService.getUser();
      if (user == null) {
        setState(() {
          _error = 'You must be logged in to view your orders.';
          _loading = false;
        });
        return;
      }
      _currentUserId = user.id;
      _currentUserName = user.fullName;

      // GET /orders?buyerId={currentUser.id}
      final data = await ApiService.getOrders(buyerId: '${user.id}');

      // buyerType lives on the raw json, not on the Order model — filter there.
      final buyerType = widget.buyerType?.toLowerCase();
      final filtered = buyerType == null || buyerType.isEmpty
          ? data
          : data.where((entry) {
              final map = entry as Map<String, dynamic>;
              final t = (map['buyerType'] ?? '').toString().toLowerCase();
              return t == buyerType;
            }).toList();

      setState(() {
        _orders = filtered
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Status badge helpers ────────────────────────────────
  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Accepté';
      case OrderStatus.cancelled:
        return 'Refusé';
      default:
        return status.label;
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _itemsSummary(Order order) {
    if (order.items.isEmpty) return 'No items';
    final first = order.items.first;
    final base =
        '${first.productName} • ${first.quantity.toStringAsFixed(0)} ${first.unit}';
    if (order.items.length > 1) {
      return '$base  (+${order.items.length - 1} more)';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Procurement Orders'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1D1A),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) => _orderCard(_orders[i]),
                      ),
                    ),
    );
  }

  Widget _orderCard(Order order) {
    final color = _statusColor(order.status);
    final isConfirmed = order.status == OrderStatus.confirmed;

    return GestureDetector(
      onTap: isConfirmed ? () => _showOrderDetailSheet(order) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _itemsSummary(order),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(order.status),
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '#ORD-${order.id}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: _primaryGreen, size: 20),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} MAD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            if (isConfirmed) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Tap for farmer & transport',
                      style: TextStyle(
                          fontSize: 11,
                          color: _primaryGreen.withOpacity(0.8),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 11, color: _primaryGreen.withOpacity(0.8)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Confirmed-order detail bottom sheet ────────────────
  void _showOrderDetailSheet(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchFarmer(order.farmerId),
          builder: (ctx, snapshot) {
            final farmer = snapshot.data;
            final farmerName = order.farmerName.isNotEmpty
                ? order.farmerName
                : (farmer?['fullName'] ?? 'Farmer').toString();
            final farmerCity = (farmer?['city'] ?? '—').toString();
            final farmerPhone = (farmer?['phone'] ?? '—').toString();
            final loadingFarmer =
                snapshot.connectionState == ConnectionState.waiting;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Order #ORD-${order.id}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_itemsSummary(order),
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Text('Farmer',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 10),
                  if (loadingFarmer)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                          child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    )
                  else ...[
                    _infoRow(Icons.person_outline, farmerName),
                    _infoRow(Icons.location_on_outlined, farmerCity),
                    _infoRow(Icons.phone_outlined, farmerPhone),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openConversation(ctx, order),
                      icon: const Text('💬', style: TextStyle(fontSize: 16)),
                      label: const Text('Ouvrir conversation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: const BorderSide(color: _primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _requestTransport(ctx, order),
                      icon: const Text('🚚', style: TextStyle(fontSize: 16)),
                      label: const Text('Demander transport'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
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

  Future<Map<String, dynamic>?> _fetchFarmer(int farmerId) async {
    if (farmerId == 0) return null;
    try {
      return await ApiService.getUserById(farmerId);
    } catch (_) {
      return null;
    }
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  void _openConversation(BuildContext sheetCtx, Order order) {
    if (_currentUserId == null) return;
    Navigator.pop(sheetCtx);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          partnerId: order.farmerId,
          partnerName: order.farmerName,
          currentUserId: _currentUserId!,
          currentUserName: _currentUserName,
        ),
      ),
    );
  }

  void _requestTransport(BuildContext sheetCtx, Order order) {
    Navigator.pop(sheetCtx);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateShipmentScreen(
          orderId: order.id ?? 0,
          farmerId: order.farmerId,
          farmerName: order.farmerName,
        ),
      ),
    );
  }
}
