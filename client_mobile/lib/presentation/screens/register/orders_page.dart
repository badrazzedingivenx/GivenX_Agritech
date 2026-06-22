import 'package:flutter/material.dart';

import '../../../models/order.dart';
import '../../../models/payment.dart';
import '../../../models/user.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  String selectedFilter = "ALL";
  List<Order> orders = [];
  final Map<int, Map<String, dynamic>> _paymentsByOrder = {};

  int? _currentUserId;
  String _currentUserName = '';
  bool _isBuyer = false;

  bool _loading = true;
  String? _error;

  // Pagination (json-server _page/_limit)
  static const int _limit = 10;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<List<dynamic>> _fetchOrdersPage(int page) async {
    final user = await SessionService.getUser();
    _currentUserId = user?.id;
    _currentUserName = user?.fullName ?? '';
    _isBuyer = user?.role == UserRole.buyer;
    final currentBuyerType = user?.buyerType?.toJson().toLowerCase();

    List<dynamic> data;
    if (user != null && user.role.name == 'farmer') {
      data = await ApiService.getOrders(
          farmerId: user.id.toString(), page: page, limit: _limit);
    } else if (user != null) {
      data = await ApiService.getOrders(
          buyerId: user.id.toString(), page: page, limit: _limit);
    } else {
      data = await ApiService.getOrders(page: page, limit: _limit);
    }

    // hasMore is decided on the raw page size (before the buyerType filter).
    _hasMore = data.length >= _limit;

    if (currentBuyerType != null &&
        currentBuyerType.isNotEmpty &&
        user?.role == UserRole.buyer) {
      data = data.where((entry) {
        final order = entry as Map<String, dynamic>;
        final orderBuyerType =
            (order['buyerType'] ?? '').toString().toLowerCase();
        return orderBuyerType == currentBuyerType;
      }).toList();
    }
    return data;
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });
    try {
      final data = await _fetchOrdersPage(_page);

      final allPayments = await ApiService.getPayments();
      final paymentsByOrder = <int, Map<String, dynamic>>{};
      for (final p in allPayments) {
        final map = p as Map<String, dynamic>;
        final orderId = map['orderId'] as int?;
        if (orderId == null) continue;
        paymentsByOrder[orderId] = map;
      }

      setState(() {
        orders = data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
        _paymentsByOrder
          ..clear()
          ..addAll(paymentsByOrder);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_loadingMore || _loading || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final data = await _fetchOrdersPage(nextPage);
      final more =
          data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        orders.addAll(more);
        _page = nextPage;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loadingMore
            ? const CircularProgressIndicator(color: Color(0xFF1B5E20))
            : OutlinedButton.icon(
                onPressed: _loadMoreOrders,
                icon: const Icon(Icons.expand_more),
                label: const Text('Charger plus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
      ),
    );
  }

  List<Order> get filteredOrders {
    if (selectedFilter == "ALL") return orders;
    return orders.where((o) {
      return o.status.label.toUpperCase() == selectedFilter;
    }).toList();
  }

  Future<void> _updateStatus(Order order, OrderStatus newStatus) async {
    if (!OrderStatus.validateStatusTransition(order.status, newStatus)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transition de statut invalide')),
        );
      }
      return;
    }
    try {
      await ApiService.updateOrder(order.id!, {'status': newStatus.toJson()});
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.amber;
      case OrderStatus.confirmed:
        return Colors.teal;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.inTransit:
        return Colors.orange;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'held':
      case 'escrow':
        return Colors.blue;
      case 'released':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.purple;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'held':
      case 'escrow':
        return 'IN ESCROW';
      case 'released':
      case 'completed':
        return 'RELEASED';
      case 'pending':
        return 'PENDING';
      case 'refunded':
        return 'REFUNDED';
      case 'failed':
        return 'FAILED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Orders"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    /// ================= FILTER TABS =================
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _filterTab("ALL"),
                          _filterTab("PROCESSING"),
                          _filterTab("DELIVERED"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    /// ================= LIST =================
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? const Center(child: Text('No orders found'))
                          : RefreshIndicator(
                              onRefresh: _loadOrders,
                              child: ListView.builder(
                                itemCount: filteredOrders.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= filteredOrders.length) {
                                    return _buildLoadMoreButton();
                                  }
                                  final order = filteredOrders[index];
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: _orderCard(order),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  /// ================= FILTER TAB =================
  Widget _filterTab(String text) {
    final isActive = selectedFilter == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = text;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// ================= ORDER CARD (SWIPE + ANIMATION) =================
  Widget _orderCard(Order order) {
    final color = _statusColor(order.status);
    final payment = _paymentsByOrder[order.id ?? -1];
    final hasPayment = order.paymentId != null || payment != null;
    final paymentStatus = (payment?['status'] as String?) ?? 'pending';
    final canPay =
        _isBuyer &&
        !hasPayment &&
        order.status != OrderStatus.cancelled &&
        order.id != null;

    final itemsSummary = order.items.map((i) => '${i.quantity.toStringAsFixed(0)}${i.unit} ${i.productName}').join(', ');

    return Dismissible(
      key: ValueKey(order.id),

      background: _swipeBackground(Icons.delete, Colors.red),
      secondaryBackground:
          _swipeBackground(Icons.check, Colors.green),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _updateStatus(order, OrderStatus.delivered);
          return false;
        } else {
          await _updateStatus(order, OrderStatus.cancelled);
          return false;
        }
      },

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TOP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.buyerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '$itemsSummary • #ORD-${order.id}',
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.shopping_bag, color: Colors.green),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} MAD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            if (hasPayment) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _paymentStatusColor(paymentStatus).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PAYMENT: ${_paymentStatusLabel(paymentStatus)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: _paymentStatusColor(paymentStatus),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],

            if (canPay) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentSheet(order),
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: const Text('Pay Now', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],

            if (order.status == OrderStatus.delivered) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewSheet(order),
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: const Text('Leave Review', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber[800],
                    side: BorderSide(color: Colors.amber[800]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet(Order order) {
    PaymentMethod method = PaymentMethod.online;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Widget methodTile(PaymentMethod value, String title, String subtitle, IconData icon) {
              final selected = method == value;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setSheetState(() => method = value),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1B5E20).withOpacity(0.08) : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? const Color(0xFF1B5E20) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFF1B5E20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Radio<PaymentMethod>(
                        value: value,
                        groupValue: method,
                        activeColor: const Color(0xFF1B5E20),
                        onChanged: (v) => setSheetState(() => method = v ?? PaymentMethod.online),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  const SizedBox(height: 18),
                  const Text(
                    'Complete Payment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Order #${order.id} • ${order.totalAmount.toStringAsFixed(2)} MAD',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  methodTile(PaymentMethod.online, 'Online Card', 'Instant escrow payment', Icons.credit_card_rounded),
                  methodTile(PaymentMethod.bankTransfer, 'Bank Transfer', 'Transfer to bank escrow', Icons.account_balance_rounded),
                  methodTile(PaymentMethod.cashOnDelivery, 'Cash on Delivery', 'Pay when delivery arrives', Icons.local_atm_rounded),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (_currentUserId == null || order.id == null) return;

                              setSheetState(() => submitting = true);
                              try {
                                final now = DateTime.now().toIso8601String();
                                final status = method == PaymentMethod.cashOnDelivery
                                    ? PaymentStatus.pending.toJson()
                                    : PaymentStatus.held.toJson();

                                final created = await ApiService.createPayment({
                                  'orderId': order.id,
                                  'buyerId': _currentUserId,
                                  'buyerName': _currentUserName,
                                  'farmerId': order.farmerId,
                                  'farmerName': order.farmerName,
                                  'userId': _currentUserId,
                                  'amount': order.totalAmount,
                                  'method': method.toJson(),
                                  'status': status,
                                  'createdAt': now,
                                  if (status == PaymentStatus.held.toJson()) 'escrowHeldAt': now,
                                });

                                final paymentId = created['id'] as int?;
                                if (paymentId != null) {
                                  await ApiService.updateOrder(order.id!, {
                                    'paymentId': paymentId,
                                    'updatedAt': now,
                                  });
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                await _loadOrders();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Payment saved successfully.'),
                                      backgroundColor: Color(0xFF1B5E20),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => submitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Payment failed: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Confirm Payment',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  /// ================= REVIEW SHEET =================
  void _showReviewSheet(Order order) {
    double rating = 5.0;
    final commentCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.rate_review_rounded, size: 40, color: Color(0xFF1B5E20)),
                const SizedBox(height: 12),
                Text(
                  'Review for Order #${order.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  order.farmerName,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setSheetState(() => rating = i + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 40,
                          color: Colors.amber[700],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  rating == 5 ? 'Excellent!' : rating >= 4 ? 'Very Good' : rating >= 3 ? 'Good' : rating >= 2 ? 'Fair' : 'Poor',
                  style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Comment
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write your review...',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : () async {
                      setSheetState(() => submitting = true);
                      try {
                        final user = await SessionService.getUser();
                        await ApiService.createReview({
                          'reviewerId': user?.id ?? 0,
                          'reviewerName': user?.fullName ?? '',
                          'targetUserId': order.farmerId,
                          'targetUserName': order.farmerName,
                          'orderId': order.id,
                          'rating': rating,
                          'comment': commentCtrl.text.trim(),
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Review submitted successfully!'),
                              backgroundColor: Color(0xFF1B5E20),
                            ),
                          );
                        }
                      } catch (e) {
                        setSheetState(() => submitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed to submit review: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  /// ================= SWIPE UI =================
  Widget _swipeBackground(IconData icon, Color color) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: color,
      child: Icon(icon, color: Colors.white),
    );
  }
}