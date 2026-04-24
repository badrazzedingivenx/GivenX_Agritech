import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../models/review.dart';
import '../../../models/shipment.dart';
import '../../../models/user.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/shared_profile_tab.dart';
import '../chat/chat_screen.dart';
import '../chat/conversations_screen.dart';

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
  List<Map<String, dynamic>> _dailyPrices = [];

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1280) return 4;
    if (width >= 900) return 3;
    return 2;
  }

  double _gridAspectRatio(BuildContext context) {
    final columns = _gridColumns(context);
    if (columns >= 4) return 0.95;
    if (columns == 3) return 0.92;
    return 1.6;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startUnreadBadgePolling();
    _startBulkPolling();
    _initDailyPrices();
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
      if (index == 4) {
        _unreadMessagesCount = 0;
      }
    });
    if (index != 4) {
      _loadUnreadMessagesCount();
    }
  }

  void _startUnreadBadgePolling() {
    _loadUnreadMessagesCount();
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(_badgePollInterval, (_) {
      if (!mounted || _currentIndex == 3) return;
      _loadUnreadMessagesCount();
    });
  }

  void _startBulkPolling() {
    _bulkTimer?.cancel();
    _bulkTimer = Timer.periodic(_bulkPollInterval, (_) {
      if (!mounted || _currentIndex == 3) return;
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

  void _initDailyPrices() {
    final now = DateTime.now();
    final dayKey = now.year * 10000 + now.month * 100 + now.day;
    final prevDayKey = now.year * 10000 + now.month * 100 + (now.day - 1);

    const baseProducts = [
      {'name': 'Tomate', 'base': 4.5},
      {'name': 'Pomme de terre', 'base': 3.0},
      {'name': 'Oignon', 'base': 2.8},
      {'name': 'Carotte', 'base': 3.5},
      {'name': 'Courgette', 'base': 5.0},
      {'name': 'Poivron', 'base': 6.2},
      {'name': 'Aubergine', 'base': 4.0},
      {'name': 'Lentilles', 'base': 8.5},
    ];

    final prices = baseProducts.map((p) {
      final name = p['name'] as String;
      final base = p['base'] as double;

      final todayRng = Random((name.hashCode ^ dayKey).abs());
      final prevRng = Random((name.hashCode ^ prevDayKey).abs());

      final todayPrice = base * (0.88 + todayRng.nextDouble() * 0.24);
      final prevPrice = base * (0.88 + prevRng.nextDouble() * 0.24);
      final change = ((todayPrice - prevPrice) / prevPrice * 100).abs();

      return {
        'name': name,
        'price': todayPrice,
        'previous': prevPrice,
        'trend': todayPrice >= prevPrice ? 'up' : 'down',
        'changePercent': change,
      };
    }).toList();

    if (mounted) setState(() => _dailyPrices = prices);
    else _dailyPrices = prices;
  }

  Future<void> _launchAgriMaroc() async {
    final uri = Uri.parse('https://agrimaroc.ma');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      userRole: 'Agriculteur',
      userId: _currentUser?.id,
      navBadgeCounts: {4: _unreadMessagesCount},
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
        NavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
        NavItem(icon: Icons.account_balance_outlined, label: 'Financing'),
        NavItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      onTabSelected: _onTabSelected,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _FarmerProductsTab(
            currentUser: _currentUser,
            green: _primaryGreen,
            textColor: _textColor,
            textLight: _textLight,
            onProductsChanged: _loadDashboardData,
          ),
          _FarmerOrdersTab(
            currentUser: _currentUser,
            green: _primaryGreen,
            textColor: _textColor,
            textLight: _textLight,
            onChanged: _loadDashboardData,
          ),
          _FarmerFinancingTab(
            currentUser: _currentUser,
            green: _primaryGreen,
            textColor: _textColor,
            textLight: _textLight,
          ),
          const ConversationsScreen(),
          _FarmerProfileTab(
            currentUser: _currentUser,
            fullName: widget.fullName,
            email: widget.email,
            phone: widget.phone,
            city: widget.city,
            farmingType: widget.farmingType,
            mainProducts: widget.mainProducts,
            green: _primaryGreen,
            textColor: _textColor,
            textLight: _textLight,
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
                  onTap: () => _onTabSelected(1),
                  child: _buildActionButton('Add\nProduct', Icons.add, true),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTabSelected(2),
                  child: _buildActionButton(
                    'Manage\nOrders',
                    Icons.receipt_long_outlined,
                    false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _dashboardStatCard(
                    icon: Icons.inventory_2,
                    label: 'Total Products',
                    value: _loading ? '...' : '$_productCount',
                    subLabel: null,
                    color: Colors.green.shade50,
                    valueColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dashboardStatCard(
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildOrdersNewsCard(),
          const SizedBox(height: 16),
          _buildPriceNewsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrdersNewsCard() {
    final pendingCount = _orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final activeCount = _orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
        .length;

    return GestureDetector(
      onTap: () => _onTabSelected(2),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF23763D), Color(0xFF155228)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF23763D).withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NOUVELLES COMMANDES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _loading
                            ? 'Chargement...'
                            : '$pendingCount commande${pendingCount != 1 ? 's' : ''} en attente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _loading
                            ? ''
                            : '$activeCount commande${activeCount != 1 ? 's' : ''} actives au total',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gérer vos commandes',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Voir →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceNewsCard() {
    final today = DateTime.now();
    final dateStr =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return GestureDetector(
      onTap: _launchAgriMaroc,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
                    Text(
                      'COURS DU MARCHÉ',
                      style: TextStyle(
                        color: _primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prix du Jour — $dateStr',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 12, color: _primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        'agrimaroc.ma',
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._dailyPrices.take(6).map((p) {
              final isUp = p['trend'] == 'up';
              final trendColor = isUp ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: trendColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p['name'] as String,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(p['price'] as double).toStringAsFixed(2)} MAD/kg',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUp ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 10,
                            color: trendColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${(p['changePercent'] as double).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: trendColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mis à jour chaque jour',
                  style: TextStyle(color: _textLight, fontSize: 11),
                ),
                GestureDetector(
                  onTap: _launchAgriMaroc,
                  child: Text(
                    'Voir plus sur agrimaroc.ma →',
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  PRODUCTS TAB  (inline – Add / View / Edit / Delete)
// ─────────────────────────────────────────────────────────────────────────────

class _FarmerProductsTab extends StatefulWidget {
  final User? currentUser;
  final Color green;
  final Color textColor;
  final Color textLight;
  final VoidCallback? onProductsChanged;

  const _FarmerProductsTab({
    required this.currentUser,
    required this.green,
    required this.textColor,
    required this.textLight,
    this.onProductsChanged,
  });

  @override
  State<_FarmerProductsTab> createState() => _FarmerProductsTabState();
}

class _FarmerProductsTabState extends State<_FarmerProductsTab> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _filterCat = 'All';

  static const _categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Other'];
  static const _units = ['Kg', 'Ton', 'Piece', 'Gram'];
  static const _catValues = ['vegetables', 'fruits', 'grains', 'other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = widget.currentUser ?? await SessionService.getUser();
      final data = await ApiService.getProducts(sellerId: user?.id?.toString());
      if (!mounted) return;
      setState(() {
        _products = data
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Product> get _filtered {
    return _products.where((p) {
      final catMatch = _filterCat == 'All' ||
          p.category.name.toLowerCase() == _filterCat.toLowerCase();
      final searchMatch =
          p.name.toLowerCase().contains(_search.toLowerCase());
      return catMatch && searchMatch;
    }).toList();
  }

  // ── Add / Edit (full-page form) ───────────────────────────────────────────

  Future<void> _openProductSheet({Product? product}) async {
    final user = widget.currentUser ?? await SessionService.getUser();
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AddProductPage(
          green: widget.green,
          textColor: widget.textColor,
          textLight: widget.textLight,
          currentUser: user,
          existingProduct: product,
        ),
      ),
    );
    await _load();
    widget.onProductsChanged?.call();
  }

  Future<void> _deleteProduct(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || p.id == null) return;
    try {
      await ApiService.deleteProduct(p.id!);
      await _load();
      widget.onProductsChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: widget.green, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.green, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _toggleChip({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? widget.green.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: value ? widget.green : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: value ? widget.green : widget.textLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? widget.green : widget.textLight,
                fontSize: 13,
                fontWeight: value ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductSheet(),
        backgroundColor: widget.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $_error',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Products',
                            style: TextStyle(
                                color: widget.green,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_products.length} product${_products.length == 1 ? '' : 's'} listed',
                            style:
                                TextStyle(color: widget.textLight, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (v) => setState(() => _search = v),
                            decoration: InputDecoration(
                              hintText: 'Search products…',
                              prefixIcon:
                                  Icon(Icons.search, color: widget.green),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final cat = _categories[i];
                                final sel = _filterCat == cat;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _filterCat = cat),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel ? widget.green : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: sel
                                              ? widget.green
                                              : Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: sel
                                            ? Colors.white
                                            : widget.textLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('No products found',
                                      style: TextStyle(
                                          color: widget.textLight,
                                          fontSize: 15)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _openProductSheet(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Product'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: widget.green,
                                        foregroundColor: Colors.white),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: widget.green,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) =>
                                    _productCard(_filtered[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  // ── Marketplace-style product card ────────────────────────────────────────

  Widget _productImage(Product p) {
    final img = p.image;
    if (img != null && img.startsWith('data:image')) {
      return Image.memory(
        base64Decode(img.split(',').last),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgPlaceholder(),
      );
    } else if (img != null && img.startsWith('assets/')) {
      return Image.asset(
        img,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgPlaceholder(),
      );
    }
    return _imgPlaceholder();
  }

  Widget _imgPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: Icon(Icons.eco, size: 60, color: widget.green.withValues(alpha: 0.4)),
    );
  }

  Widget _productCard(Product p) {
    final outOfStock = p.quantity <= 0 || !p.isAvailable;
    final stockColor = p.quantity <= 0
        ? Colors.red
        : p.quantity < 5
            ? Colors.orange
            : widget.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: Opacity(
              opacity: outOfStock ? 0.4 : 1.0,
              child: _productImage(p),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: widget.green,
                            letterSpacing: 0.1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p.price.toStringAsFixed(2)} MAD/${p.unit}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: widget.green),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Stock status
                Text(
                  outOfStock
                      ? 'OUT OF STOCK'
                      : 'In Stock: ${p.quantity.toStringAsFixed(0)} ${p.unit}',
                  style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),

                // Location + category
                const SizedBox(height: 4),
                Text(
                  [
                    if (p.location.isNotEmpty) p.location,
                    p.category.name[0].toUpperCase() +
                        p.category.name.substring(1),
                  ].join(' • '),
                  style:
                      TextStyle(color: widget.textLight, fontSize: 12),
                ),

                // Badges
                if (p.isOrganic || p.isUrgent) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (p.isOrganic)
                        _badge('🌿 Organic', Colors.green.shade700),
                      if (p.isUrgent)
                        _badge('⚡ Urgent', Colors.orange),
                    ],
                  ),
                ],

                // Description
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: widget.textLight, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 14),

                // Edit / Delete buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openProductSheet(product: p),
                      icon: const Icon(Icons.edit, size: 15),
                      label: const Text('EDIT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _deleteProduct(p),
                      icon: const Icon(Icons.delete, size: 15),
                      label: const Text('DELETE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        elevation: 0,
                      ),
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

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDERS TAB  (Accept / Reject + Request Transport + Track Delivery)
// ─────────────────────────────────────────────────────────────────────────────

class _FarmerOrdersTab extends StatefulWidget {
  final User? currentUser;
  final Color green;
  final Color textColor;
  final Color textLight;
  final VoidCallback? onChanged;

  const _FarmerOrdersTab({
    required this.currentUser,
    required this.green,
    required this.textColor,
    required this.textLight,
    this.onChanged,
  });

  @override
  State<_FarmerOrdersTab> createState() => _FarmerOrdersTabState();
}

class _FarmerOrdersTabState extends State<_FarmerOrdersTab> {
  List<Order> _orders = [];
  Map<int, Shipment?> _shipmentByOrder = {};
  bool _loading = true;
  String _filter = 'ALL';

  static const _filters = [
    'ALL',
    'PENDING',
    'CONFIRMED',
    'PROCESSING',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = widget.currentUser ?? await SessionService.getUser();
      final idStr = user?.id.toString();
      final results = await Future.wait([
        ApiService.getOrders(farmerId: idStr),
        ApiService.getShipments(),
      ]);
      final orders = (results[0] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final allShipments = (results[1] as List<dynamic>)
          .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
          .toList();

      final shipmentMap = <int, Shipment?>{};
      for (final o in orders) {
        if (o.id == null) continue;
        try {
          shipmentMap[o.id!] =
              allShipments.firstWhere((s) => s.orderId == o.id);
        } catch (_) {
          shipmentMap[o.id!] = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _shipmentByOrder = shipmentMap;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _filtered {
    if (_filter == 'ALL') return _orders;
    return _orders
        .where((o) => o.status.label.toUpperCase() == _filter)
        .toList();
  }

  Future<void> _updateStatus(Order order, OrderStatus status) async {
    try {
      await ApiService.updateOrder(order.id!, {'status': status.toJson()});
      await _load();
      widget.onChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order ${status.label.toLowerCase()}'),
        backgroundColor: widget.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openTransportSheet(Order order) async {
    final user = widget.currentUser ?? await SessionService.getUser();
    final formKey = GlobalKey<FormState>();
    final pickupCtrl = TextEditingController(text: user?.city ?? '');
    final deliveryCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('Request Transport',
                        style: TextStyle(
                            color: widget.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Order #${order.id} • ${order.buyerName}',
                        style: TextStyle(
                            color: widget.textLight, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: pickupCtrl,
                      decoration: _inputDecor(
                          'Pickup Location', Icons.my_location_outlined),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: deliveryCtrl,
                      decoration: _inputDecor(
                          'Delivery Location', Icons.location_on_outlined),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          _inputDecor('Weight (Kg)', Icons.scale_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration:
                          _inputDecor('Note (optional)', Icons.notes_outlined),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) return;
                                if (user == null || order.id == null) return;
                                setSheet(() => saving = true);
                                try {
                                  final created =
                                      await ApiService.createShipment({
                                    'orderId': order.id,
                                    'farmerId': user.id,
                                    'farmerName': user.fullName,
                                    'buyerId': order.buyerId,
                                    'buyerName': order.buyerName,
                                    'pickupLocation': pickupCtrl.text.trim(),
                                    'deliveryLocation':
                                        deliveryCtrl.text.trim(),
                                    'weight': double.tryParse(
                                        weightCtrl.text.trim()),
                                    'status': 'requested',
                                    'trackingNote': noteCtrl.text.trim(),
                                    'createdAt':
                                        DateTime.now().toIso8601String(),
                                  });
                                  await ApiService.updateOrder(order.id!, {
                                    'shipmentId': created['id'],
                                    'status':
                                        OrderStatus.processing.toJson(),
                                  });
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  await _load();
                                  widget.onChanged?.call();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        const Text('Transport requested'),
                                    backgroundColor: widget.green,
                                  ));
                                } catch (e) {
                                  setSheet(() => saving = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e')));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Request Transport'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: widget.green, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.green, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Color _orderStatusColor(OrderStatus s) {
    switch (s) {
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

  Color _shipmentStatusColor(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.requested:
        return Colors.blue;
      case ShipmentStatus.accepted:
        return Colors.teal;
      case ShipmentStatus.pickedUp:
        return Colors.orange;
      case ShipmentStatus.inTransit:
        return Colors.deepOrange;
      case ShipmentStatus.delivered:
        return Colors.green;
      case ShipmentStatus.cancelled:
        return Colors.red;
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MY ORDERS',
                  style: TextStyle(
                      color: widget.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(
                '${_orders.length} total • ${_orders.where((o) => o.status == OrderStatus.pending).length} pending',
                style: TextStyle(color: widget.textLight, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final sel = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? widget.green : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? widget.green
                                  : Colors.grey.shade300),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: sel ? Colors.white : widget.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No orders',
                              style: TextStyle(
                                  color: widget.textLight, fontSize: 15)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: widget.green,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (_, i) => _orderCard(_filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _orderCard(Order order) {
    final shipment =
        order.id != null ? _shipmentByOrder[order.id] : null;
    final statusColor = _orderStatusColor(order.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shopping_basket,
                      color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.buyerName.isNotEmpty
                            ? order.buyerName
                            : 'Order #${order.id}',
                        style: TextStyle(
                            color: widget.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '#ORD-${order.id} • ${_fmtDate(order.createdAt)}',
                        style: TextStyle(
                            color: widget.textLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.label.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          size: 6, color: widget.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.productName} — ${item.quantity.toStringAsFixed(0)} ${item.unit} @ ${item.unitPrice.toStringAsFixed(2)} MAD',
                          style: TextStyle(
                              color: widget.textLight, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 6),
            Text(
              'Total: ${order.totalAmount.toStringAsFixed(2)} MAD',
              style: TextStyle(
                  color: widget.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
            if (shipment != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9F3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: widget.green.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping,
                            color: widget.green, size: 16),
                        const SizedBox(width: 6),
                        Text('Shipment Tracking',
                            style: TextStyle(
                                color: widget.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _shipmentStatusColor(shipment.status)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            shipment.status.label.toUpperCase(),
                            style: TextStyle(
                                color: _shipmentStatusColor(
                                    shipment.status),
                                fontSize: 9,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _trackRow(Icons.my_location_outlined,
                        shipment.pickupLocation, 'Pickup'),
                    _trackRow(Icons.location_on_outlined,
                        shipment.deliveryLocation, 'Delivery'),
                    if (shipment.transporterName != null)
                      _trackRow(Icons.drive_eta_outlined,
                          shipment.transporterName!, 'Transporter'),
                    if (shipment.trackingNote != null &&
                        shipment.trackingNote!.isNotEmpty)
                      _trackRow(Icons.notes_outlined,
                          shipment.trackingNote!, 'Note'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildOrderActions(order, shipment),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(Order order, Shipment? shipment) {
    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _updateStatus(order, OrderStatus.confirmed),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  _updateStatus(order, OrderStatus.cancelled),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    }
    if (order.status == OrderStatus.confirmed && shipment == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openTransportSheet(order),
          icon: const Icon(Icons.local_shipping_outlined, size: 16),
          label: const Text('Request Transport'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
    }
    if (order.status == OrderStatus.processing ||
        order.status == OrderStatus.inTransit) {
      return Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            shipment != null
                ? 'Shipment in progress — ${shipment.status.label}'
                : 'Order in progress',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      );
    }
    if (order.status == OrderStatus.delivered) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 16, color: widget.green),
          const SizedBox(width: 6),
          Text('Order delivered',
              style: TextStyle(
                  color: widget.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );
    }
    if (order.status == OrderStatus.cancelled) {
      return const Row(
        children: [
          Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
          SizedBox(width: 6),
          Text('Order cancelled',
              style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _trackRow(IconData icon, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: widget.textLight),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(
                  color: widget.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style:
                    TextStyle(color: widget.textColor, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FINANCING TAB  (farmer loan/financing requests to banks)
// ─────────────────────────────────────────────────────────────────────────────

class _FarmerFinancingTab extends StatefulWidget {
  final User? currentUser;
  final Color green;
  final Color textColor;
  final Color textLight;

  const _FarmerFinancingTab({
    required this.currentUser,
    required this.green,
    required this.textColor,
    required this.textLight,
  });

  @override
  State<_FarmerFinancingTab> createState() => _FarmerFinancingTabState();
}

class _FarmerFinancingTabState extends State<_FarmerFinancingTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  static const _purposes = [
    'equipment',
    'seeds',
    'infrastructure',
    'land',
    'other',
  ];
  static const _purposeLabels = {
    'equipment': 'Equipment / Machinery',
    'seeds': 'Seeds & Inputs',
    'infrastructure': 'Infrastructure',
    'land': 'Land Purchase',
    'other': 'Other',
  };
  static const _purposeIcons = {
    'equipment': Icons.agriculture,
    'seeds': Icons.grass,
    'infrastructure': Icons.construction,
    'land': Icons.landscape,
    'other': Icons.more_horiz,
  };
  static const _purposeColors = {
    'equipment': Color(0xFF1565C0),
    'seeds': Color(0xFF2E7D32),
    'infrastructure': Color(0xFFE65100),
    'land': Color(0xFF6D4C41),
    'other': Color(0xFF6A1B9A),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = widget.currentUser ?? await SessionService.getUser();
      final data = await ApiService.getFinanceRequests(farmerId: user?.id?.toString());
      if (!mounted) return;
      setState(() {
        _requests = data.cast<Map<String, dynamic>>();
        _requests.sort((a, b) {
          final aDate = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openNewRequestSheet() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPurpose = 'equipment';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.account_balance, color: widget.green, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'New Finance Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: widget.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Banks will review your request and may contact you.',
                        style: TextStyle(fontSize: 12, color: widget.textLight),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      TextFormField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Request Title',
                          hintText: 'e.g. Purchase of tractor',
                          prefixIcon: Icon(Icons.title, color: widget.green, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: widget.green, width: 2),
                          ),
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 12),
                      // Amount
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount Needed (MAD)',
                          hintText: 'e.g. 200000',
                          prefixIcon: Icon(Icons.payments_outlined, color: const Color(0xFF1565C0), size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                          ),
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter a valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Purpose
                      Text(
                        'Purpose',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _purposes.map((p) {
                          final isSelected = selectedPurpose == p;
                          final color = _purposeColors[p] ?? widget.green;
                          return GestureDetector(
                            onTap: () => setModal(() => selectedPurpose = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? color : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _purposeIcons[p] ?? Icons.more_horiz,
                                    color: isSelected ? color : widget.textLight,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _purposeLabels[p] ?? p,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected ? color : widget.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      // Description
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe your financing need in detail...',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.description_outlined, color: widget.green, size: 20),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: widget.green, width: 2),
                          ),
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ?? false)) return;
                                  final user = widget.currentUser ??
                                      await SessionService.getUser();
                                  if (user == null) return;
                                  setModal(() => submitting = true);
                                  try {
                                    await ApiService.createFinanceRequest({
                                      'farmerId': user.id,
                                      'farmerName': user.fullName,
                                      'farmerCity': user.city,
                                      'farmerPhone': user.phone,
                                      'title': titleCtrl.text.trim(),
                                      'amount': double.parse(amountCtrl.text.trim()),
                                      'purpose': selectedPurpose,
                                      'description': descCtrl.text.trim(),
                                      'status': 'pending',
                                      'createdAt': DateTime.now().toIso8601String(),
                                    });
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    await _load();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Finance request submitted to banks'),
                                        backgroundColor: widget.green,
                                      ),
                                    );
                                  } catch (e) {
                                    setModal(() => submitting = false);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                        backgroundColor: Colors.red.shade700,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                },
                          icon: submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(submitting ? 'Submitting...' : 'Submit Request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRequest(Map<String, dynamic> req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text('Delete "${req['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = req['id'];
    if (id == null) return;
    try {
      await ApiService.deleteFinanceRequest(id is int ? id : int.parse(id.toString()));
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request deleted')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to delete')));
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'reviewing':
        return const Color(0xFF1565C0);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'APPROVED';
      case 'reviewing':
        return 'REVIEWING';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F3),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FINANCING',
                          style: TextStyle(
                            color: widget.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Agricultural Finance',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: widget.textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Post your funding needs. Banks will review and may contact you.',
                          style: TextStyle(fontSize: 13, color: widget.textLight),
                        ),
                        const SizedBox(height: 16),
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.green,
                                const Color(0xFF388E3C),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'How it works',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Post your request → Banks review → Bank contacts you to discuss the loan.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // New request button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openNewRequestSheet,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('New Finance Request'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'My Requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: widget.textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (_requests.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_outlined,
                              size: 64, color: widget.textLight),
                          const SizedBox(height: 12),
                          Text(
                            'No financing requests yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: widget.textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap the button above to post your first request.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: widget.textLight),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final req = _requests[i];
                          final status = (req['status'] ?? 'pending').toString();
                          final purpose = (req['purpose'] ?? 'other').toString();
                          final purposeColor =
                              _purposeColors[purpose] ?? widget.green;
                          final purposeIcon =
                              _purposeIcons[purpose] ?? Icons.more_horiz;
                          final amount = req['amount'];
                          final amountStr = amount != null
                              ? '${(amount as num).toStringAsFixed(0)} MAD'
                              : '—';
                          final dateStr = req['createdAt'] != null
                              ? DateTime.tryParse(req['createdAt'].toString())
                                      ?.toLocal()
                                      .toString()
                                      .split(' ')
                                      .first ??
                                  ''
                              : '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: purposeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(purposeIcon,
                                            color: purposeColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              req['title']?.toString() ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: widget.textColor,
                                              ),
                                            ),
                                            Text(
                                              _purposeLabels[purpose] ?? purpose,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: purposeColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    req['description']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13, color: widget.textLight),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.payments_outlined,
                                          size: 16,
                                          color: const Color(0xFF1565C0)),
                                      const SizedBox(width: 6),
                                      Text(
                                        amountStr,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (dateStr.isNotEmpty)
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: widget.textLight),
                                        ),
                                    ],
                                  ),
                                  if (status == 'pending') ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _deleteRequest(req),
                                        icon: const Icon(Icons.delete_outline,
                                            size: 16, color: Colors.red),
                                        label: const Text('Delete',
                                            style: TextStyle(color: Colors.red, fontSize: 12)),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _requests.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROFILE TAB  (info + reviews + verification status)
// ─────────────────────────────────────────────────────────────────────────────

class _FarmerProfileTab extends StatefulWidget {
  final User? currentUser;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String farmingType;
  final String mainProducts;
  final Color green;
  final Color textColor;
  final Color textLight;

  const _FarmerProfileTab({
    required this.currentUser,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.farmingType,
    required this.mainProducts,
    required this.green,
    required this.textColor,
    required this.textLight,
  });

  @override
  State<_FarmerProfileTab> createState() => _FarmerProfileTabState();
}

class _FarmerProfileTabState extends State<_FarmerProfileTab> {
  List<Review> _reviews = [];
  bool _reviewsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final user = widget.currentUser ?? await SessionService.getUser();
      if (user == null) {
        if (mounted) setState(() => _reviewsLoading = false);
        return;
      }
      final data =
          await ApiService.getReviews(targetUserId: user.id.toString());
      if (!mounted) return;
      setState(() {
        _reviews = data
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _reviewsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return SharedProfileTab(
      fullName: widget.fullName,
      subtitle: 'FARMER • ${widget.city}',
      primaryGreen: widget.green,
      textColor: widget.textColor,
      textLight: widget.textLight,
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
                icon: Icons.eco_outlined,
                iconColor: const Color(0xFF2E7D32),
                label: 'FARMING TYPE',
                value: widget.farmingType,
              ),
              ProfileInfoItem(
                icon: Icons.grass_outlined,
                iconColor: const Color(0xFF558B2F),
                label: 'MAIN PRODUCTS',
                value: widget.mainProducts,
              ),
            ],
            extraContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Buyer Reviews ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Buyer Reviews',
                          style: TextStyle(
                              fontSize: 17,
                              color: widget.textColor,
                              fontWeight: FontWeight.w800)),
                      if (!_reviewsLoading && _reviews.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _avgRating.toStringAsFixed(1),
                                style: TextStyle(
                                    color: widget.green,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13),
                              ),
                              Text(
                                ' (${_reviews.length})',
                                style: TextStyle(
                                    color: widget.textLight,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_reviewsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    Container(
                      width: double.infinity,
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
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.star_border,
                                color: Colors.amber, size: 22),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REVIEWS',
                                  style: TextStyle(
                                      color: Colors.amber.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0)),
                              const SizedBox(height: 6),
                              Text('No reviews yet',
                                  style: TextStyle(
                                      color: widget.textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (_, i) => _reviewCard(_reviews[i]),
                    ),
                ],
              ),
            ),
          );
  }

  /// Styled to match Account Information tiles in SharedProfileTab.
  Widget _verificationTile(
      IconData icon, String label, String title, bool verified) {
    final color = verified ? widget.green : Colors.grey;
    return Container(
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Text(title,
                    style: TextStyle(
                        color: widget.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              verified ? 'Verified' : 'Pending',
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Review r) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              r.reviewerName.isNotEmpty
                  ? r.reviewerName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: widget.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('REVIEW',
                        style: TextStyle(
                            color: widget.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < r.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.reviewerName.isNotEmpty ? r.reviewerName : 'Anonymous',
                  style: TextStyle(
                      color: widget.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
                if (r.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(r.comment,
                      style: TextStyle(
                          color: widget.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 4),
                Text(_fmtDate(r.createdAt),
                    style:
                        TextStyle(color: widget.textLight, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD / EDIT PRODUCT  — full-page form with photo picker + card sections
// ─────────────────────────────────────────────────────────────────────────────

class _AddProductPage extends StatefulWidget {
  final User? currentUser;
  final Product? existingProduct;
  final Color green;
  final Color textColor;
  final Color textLight;

  const _AddProductPage({
    required this.currentUser,
    required this.green,
    required this.textColor,
    required this.textLight,
    this.existingProduct,
  });

  @override
  State<_AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<_AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final List<Uint8List> _images = [];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _descCtrl;

  static const _units = ['Kg', 'Ton', 'Piece', 'Gram', 'Bag (50kg)', 'Bag (25kg)'];
  static const _catValues = ['vegetables', 'fruits', 'grains', 'other'];

  String _unit = 'Kg';
  String _cat = 'vegetables';
  bool _organic = false;
  bool _urgent = false;
  bool _saving = false;

  bool get _isEdit => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price != null ? p!.price.toString() : '');
    _qtyCtrl = TextEditingController(text: p?.quantity != null ? p!.quantity.toString() : '');
    _locCtrl = TextEditingController(text: p?.location ?? widget.currentUser?.city ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _unit = p?.unit ?? 'Kg';
    _cat = p?.category.name ?? 'vegetables';
    _organic = p?.isOrganic ?? false;
    _urgent = p?.isUrgent ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _locCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 75);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (_images.length < 3) _images.add(bytes);
    });
  }

  void _showImageSource() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: widget.green),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: widget.green),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = widget.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      String? imageBase64;
      if (_images.isNotEmpty) {
        imageBase64 = 'data:image/png;base64,${base64Encode(_images.first)}';
      }

      final p = widget.existingProduct;
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'quantity': double.parse(_qtyCtrl.text.trim()),
        'location': _locCtrl.text.trim(),
        'unit': _unit,
        'category': _cat,
        'description': _descCtrl.text.trim(),
        'isOrganic': _organic,
        'isUrgent': _urgent,
        'isAvailable': true,
        'farmerId': user.id,
        'farmerName': user.fullName,
        'images': <String>[],
        'createdAt': _isEdit
            ? p!.createdAt.toIso8601String()
            : DateTime.now().toIso8601String(),
        if (imageBase64 != null) 'image': imageBase64,
      };

      if (_isEdit && p!.id != null) {
        await ApiService.updateProduct(p.id!, payload);
      } else {
        await ApiService.createProduct(payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Product updated' : 'Product added!'),
        backgroundColor: widget.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  /// A card-tile identical to the shared_profile_tab info-tile pattern,
  /// but wraps an interactive form [child] instead of a static text value.
  Widget _fieldTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F9F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _cleanField(String hint) => InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        isDense: true,
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 15),
        contentPadding: EdgeInsets.zero,
        errorStyle: const TextStyle(fontSize: 11),
      );

  TextStyle get _fieldValueStyle => TextStyle(
        color: widget.textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6, left: 2),
      child: Text(
        title,
        style: TextStyle(
            color: widget.green,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _toggle(String label, IconData icon, Color iconColor,
      bool value, ValueSetter<bool> onChanged) {
    return GestureDetector(
      onTap: () => setState(() => onChanged(!value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: value
              ? iconColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: value
                  ? iconColor
                  : Colors.grey.shade200,
              width: value ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: value
                    ? iconColor.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18,
                  color: value ? iconColor : Colors.grey.shade400),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: value ? iconColor : widget.textLight,
                    fontWeight:
                        value ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close, color: widget.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Product' : 'Add Product',
          style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [

            // ── PHOTOS ────────────────────────────────────────────────
            _sectionTitle('PRODUCT PHOTOS (MAX 3)'),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Newly picked images
                    ..._images.asMap().entries.map((e) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: MemoryImage(e.value),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ],
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _images.removeAt(e.key)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                    // Existing image in edit mode (before any new pick)
                    if (_isEdit &&
                        _images.isEmpty &&
                        (widget.existingProduct?.image?.isNotEmpty ??
                            false))
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.shade100,
                          image: DecorationImage(
                            image: (widget.existingProduct!.image!
                                    .startsWith('data:image'))
                                ? MemoryImage(base64Decode(widget
                                    .existingProduct!.image!
                                    .split(',')
                                    .last)) as ImageProvider
                                : AssetImage(
                                    widget.existingProduct!.image!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    // Add-photo button
                    if (_images.length < 3)
                      GestureDetector(
                        onTap: _showImageSource,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: widget.green.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    widget.green.withValues(alpha: 0.35),
                                width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: widget.green
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add_a_photo_outlined,
                                    color: widget.green, size: 22),
                              ),
                              const SizedBox(height: 6),
                              Text('Add Photo',
                                  style: TextStyle(
                                      color: widget.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── PRODUCT INFO ──────────────────────────────────────────
            _sectionTitle('PRODUCT INFO'),

            _fieldTile(
              icon: Icons.eco,
              iconColor: const Color(0xFF2E7D32),
              label: 'PRODUCT NAME',
              child: TextFormField(
                controller: _nameCtrl,
                style: _fieldValueStyle,
                decoration: _cleanField('e.g. Fresh Red Apples'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
              ),
            ),

            _fieldTile(
              icon: Icons.category_rounded,
              iconColor: const Color(0xFF5C6BC0),
              label: 'CATEGORY',
              child: DropdownButtonFormField<String>(
                value: _cat,
                style: _fieldValueStyle,
                decoration: _cleanField(''),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF5C6BC0)),
                dropdownColor: Colors.white,
                items: _catValues
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child:
                            Text(c[0].toUpperCase() + c.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _cat = v ?? _cat),
              ),
            ),

            _fieldTile(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFFAD1457),
              label: 'LOCATION / CITY',
              child: TextFormField(
                controller: _locCtrl,
                style: _fieldValueStyle,
                decoration: _cleanField('e.g. Agadir'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Location is required' : null,
              ),
            ),

            const SizedBox(height: 8),

            // ── PRICING & STOCK ───────────────────────────────────────
            _sectionTitle('PRICING & STOCK'),

            Row(
              children: [
                Expanded(
                  child: _fieldTile(
                    icon: Icons.sell_rounded,
                    iconColor: const Color(0xFF1565C0),
                    label: 'PRICE (MAD)',
                    child: TextFormField(
                      controller: _priceCtrl,
                      style: _fieldValueStyle,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _cleanField('0.00'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _fieldTile(
                    icon: Icons.scale_rounded,
                    iconColor: const Color(0xFF00695C),
                    label: 'QUANTITY',
                    child: TextFormField(
                      controller: _qtyCtrl,
                      style: _fieldValueStyle,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _cleanField('0'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Invalid qty';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),

            _fieldTile(
              icon: Icons.straighten_rounded,
              iconColor: const Color(0xFFE65100),
              label: 'UNIT',
              child: DropdownButtonFormField<String>(
                value: _unit,
                style: _fieldValueStyle,
                decoration: _cleanField(''),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFFE65100)),
                dropdownColor: Colors.white,
                items: _units
                    .map((u) =>
                        DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
            ),

            const SizedBox(height: 8),

            // ── DETAILS ───────────────────────────────────────────────
            _sectionTitle('DETAILS'),

            _fieldTile(
              icon: Icons.notes_rounded,
              iconColor: const Color(0xFF6A1B9A),
              label: 'DESCRIPTION (OPTIONAL)',
              child: TextFormField(
                controller: _descCtrl,
                style: _fieldValueStyle,
                maxLines: 3,
                decoration: _cleanField(
                    'Describe your product quality, origin…'),
              ),
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: _toggle(
                    'Organic',
                    Icons.spa_rounded,
                    const Color(0xFF2E7D32),
                    _organic,
                    (v) => _organic = v,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _toggle(
                    'Urgent',
                    Icons.flash_on_rounded,
                    const Color(0xFFE65100),
                    _urgent,
                    (v) => _urgent = v,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── SAVE BUTTON ───────────────────────────────────────────
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(
                        _isEdit ? 'Save Changes' : 'CONFIRM & SAVE',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
