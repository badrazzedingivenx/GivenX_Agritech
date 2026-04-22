import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/order.dart';
import '../../../models/user.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../chat/chat_screen.dart';
import '../chat/conversations_screen.dart';
import '../products/addproducts_page.dart';
import '../products/products_page.dart';
import '../profile_farmer.dart';
import '../register/orders_page.dart';

class FarmerDashboard extends StatefulWidget {
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
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _textColor = Color(0xFF1A1D1A);
  static const Color _textLight = Color(0xFF757575);

  int _currentIndex = 0;
  int _productCount = 0;
  List<Order> _orders = [];
  double _totalEarnings = 0;
  bool _loading = true;
  bool _bulkLoading = true;
  int _unreadMessagesCount = 0;
  static const Duration _badgePollInterval = Duration(seconds: 10);
  static const Duration _bulkPollInterval = Duration(seconds: 8);
  Timer? _badgeTimer;
  Timer? _bulkTimer;
  User? _currentUser;
  List<Map<String, dynamic>> _bulkRequests = [];
  Map<int, List<Map<String, dynamic>>> _offersByRequest = {};

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

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
    return 1.18;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startUnreadBadgePolling();
    _startBulkPolling();
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _bulkTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = await SessionService.getUser();
      _currentUser = user;
      final farmerId = user?.id.toString();

      final productsFuture = ApiService.getProducts(sellerId: farmerId);
      final ordersFuture = ApiService.getOrders(farmerId: farmerId);
      final bulkRequestsFuture = ApiService.getBulkRequests();
      final bulkOffersFuture = ApiService.getBulkOffers();
      final unreadMessagesFuture = ApiService.getMessages(receiverId: farmerId);
      final results = await Future.wait([
        productsFuture,
        ordersFuture,
        bulkRequestsFuture,
        bulkOffersFuture,
        unreadMessagesFuture,
      ]);

      final products = results[0];
      final ordersJson = results[1];
      final orders = ordersJson
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      final requestsJson = (results[2] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final offersJson = (results[3] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final unreadMessages = (results[4] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final requests = requestsJson
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

      final groupedOffers = <int, List<Map<String, dynamic>>>{};
      for (final offer in offersJson) {
        final requestId = _asInt(offer['requestId']);
        if (requestId == null) continue;
        groupedOffers.putIfAbsent(requestId, () => []).add(offer);
      }

      final earnings = orders
          .where((o) => o.status == OrderStatus.delivered)
          .fold<double>(0, (sum, o) => sum + o.totalAmount);

      if (mounted) {
        setState(() {
          _productCount = products.length;
          _orders = orders;
          _totalEarnings = earnings;
          _bulkRequests = requests;
          _offersByRequest = groupedOffers;
          _unreadMessagesCount = unreadMessages.where((m) => m['isRead'] == false).length;
          _loading = false;
          _bulkLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _bulkLoading = false;
        });
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 2) {
        _unreadMessagesCount = 0;
      }
    });
    if (index != 2) {
      _loadUnreadMessagesCount();
    }
  }

  void _startUnreadBadgePolling() {
    _loadUnreadMessagesCount();
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(_badgePollInterval, (_) {
      if (!mounted || _currentIndex == 2) return;
      _loadUnreadMessagesCount();
    });
  }

  void _startBulkPolling() {
    _bulkTimer?.cancel();
    _bulkTimer = Timer.periodic(_bulkPollInterval, (_) {
      if (!mounted || _currentIndex == 2) return;
      _refreshBulkRequestsAndOffers();
    });
  }

  Future<void> _refreshBulkRequestsAndOffers() async {
    try {
      final requestsRaw = await ApiService.getBulkRequests();
      final offersRaw = await ApiService.getBulkOffers();

      final requestsJson = requestsRaw.cast<Map<String, dynamic>>();
      final offersJson = offersRaw.cast<Map<String, dynamic>>();

      final requests = requestsJson
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

      final groupedOffers = <int, List<Map<String, dynamic>>>{};
      for (final offer in offersJson) {
        final requestId = _asInt(offer['requestId']);
        if (requestId == null) continue;
        groupedOffers.putIfAbsent(requestId, () => []).add(offer);
      }

      if (!mounted) return;
      setState(() {
        _bulkRequests = requests;
        _offersByRequest = groupedOffers;
      });
    } catch (_) {}
  }

  Future<void> _loadUnreadMessagesCount() async {
    try {
      final user = _currentUser ?? await SessionService.getUser();
      if (user == null) return;
      _currentUser ??= user;
      final received = await ApiService.getMessages(receiverId: '${user.id}');
      final unread = received
          .cast<Map<String, dynamic>>()
          .where((m) => m['isRead'] == false)
          .length;
      if (!mounted) return;
      setState(() => _unreadMessagesCount = unread);
    } catch (_) {}
  }

  List<Map<String, dynamic>> _offersForRequest(Map<String, dynamic> request) {
    final requestId = _asInt(request['id']);
    if (requestId == null) return const [];
    final requestCreatedAt = DateTime.tryParse((request['createdAt'] ?? '').toString());

    return List<Map<String, dynamic>>.from(_offersByRequest[requestId] ?? const [])
        .where((offer) {
          if (requestCreatedAt == null) return true;
          final offerCreatedAt = DateTime.tryParse((offer['createdAt'] ?? '').toString());
          if (offerCreatedAt == null) return false;
          return !offerCreatedAt.isBefore(requestCreatedAt);
        })
        .toList();
  }

  bool _myOfferExists(Map<String, dynamic> request) {
    final myId = _currentUser?.id;
    if (myId == null) return false;
    return _offersForRequest(request)
        .any((o) => _asInt(o['farmerId']) == myId);
  }

  Future<void> _openSubmitOfferSheet(Map<String, dynamic> request) async {
    final formKey = GlobalKey<FormState>();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(
      text: (request['quantity'] ?? '').toString(),
    );
    final noteCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Propose Offer',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      request['productName']?.toString() ?? 'Product',
                      style: TextStyle(color: _textLight, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price / Unit (MAD)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Proposed Quantity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Invalid quantity';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ?? false)) return;

                                final user = _currentUser ?? await SessionService.getUser();
                                final requestId = _asInt(request['id']);
                                final buyerId = _asInt(request['buyerId']);
                                if (user == null || requestId == null || buyerId == null) return;

                                setModalState(() => submitting = true);

                                try {
                                  await ApiService.createBulkOffer({
                                    'requestId': requestId,
                                    'requestCreatedAt': request['createdAt'],
                                    'farmerId': user.id,
                                    'farmerName': user.fullName,
                                    'pricePerUnit': double.parse(priceCtrl.text.trim()),
                                    'proposedQuantity': double.parse(qtyCtrl.text.trim()),
                                    'note': noteCtrl.text.trim(),
                                    'status': 'pending',
                                    'createdAt': DateTime.now().toIso8601String(),
                                  });

                                  await ApiService.sendMessage({
                                    'senderId': user.id,
                                    'senderName': user.fullName,
                                    'receiverId': buyerId,
                                    'receiverName': request['buyerName'] ?? 'Buyer',
                                    'content': 'New bulk offer sent for ${request['productName']}. Please review it.',
                                    'isRead': false,
                                    'createdAt': DateTime.now().toIso8601String(),
                                  });

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  await _loadDashboardData();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Offer submitted to buyer successfully'),
                                      backgroundColor: _primaryGreen,
                                    ),
                                  );
                                } catch (_) {
                                  setModalState(() => submitting = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Failed to submit offer')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send Offer'),
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

  Widget _buildBulkRequestsSection() {
    if (_bulkLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bulkRequests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text('No bulk requests from industry yet'),
      );
    }

    return ListView.separated(
      itemCount: _bulkRequests.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = _bulkRequests[index];
        final requestId = _asInt(request['id']) ?? -1;
        final offers = requestId == -1 ? <Map<String, dynamic>>[] : _offersForRequest(request);
        final myOffer = _myOfferExists(request);
        final acceptedOfferId = _asInt(request['acceptedOfferId']);
        final myAccepted = acceptedOfferId != null &&
            offers.any((o) => _asInt(o['id']) == acceptedOfferId && _asInt(o['farmerId']) == _currentUser?.id);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request['productName']?.toString() ?? 'Product',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Buyer: ${request['buyerName'] ?? 'Industry'}',
                style: TextStyle(color: _textLight, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${request['quantity']} ${request['unit']} • Budget ${request['budget']} MAD',
                style: TextStyle(color: _textLight, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (myAccepted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Your offer was accepted. Continue via Messages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _primaryGreen, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: myOffer
                            ? null
                            : () => _openSubmitOfferSheet(request),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(myOffer ? 'Offer Sent' : 'Propose Offer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        final buyerId = _asInt(request['buyerId']);
                        final buyerName = request['buyerName']?.toString() ?? 'Buyer';
                        final currentUserId = _currentUser?.id;
                        final currentUserName = _currentUser?.fullName;
                        if (buyerId == null || currentUserId == null || currentUserName == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              partnerId: buyerId,
                              partnerName: buyerName,
                              currentUserId: currentUserId,
                              currentUserName: currentUserName,
                            ),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                      child: const Text('Open chat with buyer'),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: _currentIndex,
      navBadgeCounts: {2: _unreadMessagesCount},
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.shopping_bag_outlined, label: 'Products'),
        NavItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
        NavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      onTabSelected: _onTabSelected,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const ProductsPage(),
          const ConversationsScreen(),
          const OrdersPage(),
          ProfileFarmerPage(
            fullName: widget.fullName,
            email: widget.email,
            phone: widget.phone,
            city: widget.city,
            farmingType: widget.farmingType,
            mainProducts: widget.mainProducts,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FARMER DASHBOARD',
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hello, ${widget.fullName}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here is the status of your supply activity today.',
            style: TextStyle(fontSize: 13, color: _textLight),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddProductPage(),
                      ),
                    );
                  },
                  child: _buildActionButton('Add\nProduct', Icons.add, true),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductsPage(),
                      ),
                    );
                  },
                  child: _buildActionButton(
                    'Manage\nProducts',
                    Icons.inventory_2_outlined,
                    false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: _gridColumns(context),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: _gridAspectRatio(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _dashboardStatCard(
                icon: Icons.inventory_2,
                label: 'Total Products',
                value: _loading ? '...' : '$_productCount',
                subLabel: null,
                color: Colors.green.shade50,
                valueColor: Colors.green,
              ),
              _dashboardStatCard(
                icon: Icons.local_shipping,
                label: 'Active Orders',
                value: _loading
                    ? '...'
                    : '${_orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).length}',
                subLabel: _loading
                    ? null
                    : '${_orders.where((o) => o.status == OrderStatus.pending).length} pending',
                color: Colors.pink.shade50,
                valueColor: Colors.pink,
              ),
              _dashboardStatCard(
                icon: Icons.attach_money,
                label: 'Total Earnings',
                value: _loading ? '...' : '${_totalEarnings.toStringAsFixed(0)} MAD',
                subLabel: null,
                color: Colors.green.shade50,
                valueColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrdersPage(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_orders.isEmpty)
            const Center(child: Text('No activity yet'))
          else
            GridView.count(
              crossAxisCount: _gridColumns(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: _gridAspectRatio(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _orders.take(4).map((order) {
                final itemsSummary = order.items
                    .map((i) => '${i.quantity.toStringAsFixed(0)}${i.unit} ${i.productName}')
                    .join(', ');
                return _recentOrderTile(
                  order.buyerName,
                  '$itemsSummary • #ORD-${order.id}',
                  order.status.label.toUpperCase(),
                  '${order.totalAmount.toStringAsFixed(2)} MAD',
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Industry Bulk Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _loadDashboardData,
                child: const Text('Refresh'),
              ),
            ],
          ),
          _buildBulkRequestsSection(),
          const SizedBox(height: 28),
          _topSellingCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isPrimary ? _primaryGreen : Colors.white,
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
          Icon(icon, color: isPrimary ? Colors.white : _textColor, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isPrimary ? Colors.white : _textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? subLabel,
    required Color color,
    required Color valueColor,
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
            offset: const Offset(0, 6),
          )
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
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: valueColor, size: 24),
              ),
              if (subLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subLabel,
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: _textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _textLight, fontSize: 12),
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
        statusColor = Colors.orange;
        break;
      case 'PROCESSING':
        statusColor = Colors.blue;
        break;
      case 'DELIVERED':
      case 'COMPLETED':
        statusColor = Colors.green;
        break;
      case 'PENDING':
        statusColor = Colors.amber;
        break;
      case 'CONFIRMED':
        statusColor = Colors.teal;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_basket,
              color: Color(0xFF5A5E5A),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                amount,
                style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topSellingCard() {
    final totalsByProduct = <String, double>{};
    for (final order in _orders) {
      for (final item in order.items) {
        if (item.productName.trim().isEmpty) continue;
        totalsByProduct.update(
          item.productName,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }

    String topProduct = 'No sales yet';
    double topQuantity = 0;
    double totalQuantity = 0;
    if (totalsByProduct.isNotEmpty) {
      final sorted = totalsByProduct.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topProduct = sorted.first.key;
      topQuantity = sorted.first.value;
      totalQuantity = totalsByProduct.values.fold(0.0, (sum, v) => sum + v);
    }

    final progress =
        totalQuantity > 0 ? (topQuantity / totalQuantity).clamp(0, 1).toDouble() : 0.0;
    final progressLabel =
        _loading ? '...' : '${(progress * 100).toStringAsFixed(0)}%';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
            Text(
              'TOP SELLING',
              style: TextStyle(
                fontSize: 11,
                color: _primaryGreen,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _loading ? 'Loading sales data...' : topProduct,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _loading
                  ? ''
                  : topQuantity > 0
                      ? '${topQuantity.toStringAsFixed(0)} units sold'
                      : 'No fulfilled sales yet',
              style: TextStyle(fontSize: 13, color: _textLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Yield Progress'),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.green.shade100,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Text(progressLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
