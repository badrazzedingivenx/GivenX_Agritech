import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class FarmerDashboardViewModel extends ChangeNotifier {
  static const Duration badgePollInterval = Duration(seconds: 10);
  static const Duration bulkPollInterval = Duration(seconds: 8);

  bool loading = true;
  bool bulkLoading = true;
  int productCount = 0;
  List<Order> orders = [];
  double totalEarnings = 0;
  int unreadMessagesCount = 0;
  User? currentUser;
  List<Map<String, dynamic>> bulkRequests = [];
  Map<int, List<Map<String, dynamic>>> offersByRequest = {};
  List<Map<String, dynamic>> dailyPrices = [];

  Timer? _badgeTimer;
  Timer? _bulkTimer;

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> loadDashboardData() async {
    try {
      final user = await SessionService.getUser();
      currentUser = user;
      final farmerId = user?.id.toString();

      final results = await Future.wait([
        ApiService.getProducts(sellerId: farmerId),
        ApiService.getOrders(farmerId: farmerId),
        ApiService.getBulkRequests(),
        ApiService.getBulkOffers(),
        ApiService.getMessages(receiverId: farmerId),
      ]);

      final products = results[0];
      final ordersJson = results[1];
      final fetchedOrders = ordersJson
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      final requestsJson =
          (results[2] as List<dynamic>).cast<Map<String, dynamic>>();
      final offersJson =
          (results[3] as List<dynamic>).cast<Map<String, dynamic>>();
      final unreadMessages =
          (results[4] as List<dynamic>).cast<Map<String, dynamic>>();

      final requests = requestsJson
          .where((r) {
            final status = (r['status'] ?? '').toString().toLowerCase();
            final acceptedOfferId = _asInt(r['acceptedOfferId']);
            return status == 'open' && acceptedOfferId == null;
          })
          .toList()
        ..sort((a, b) {
          final aDate =
              DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      final groupedOffers = <int, List<Map<String, dynamic>>>{};
      for (final offer in offersJson) {
        final requestId = _asInt(offer['requestId']);
        if (requestId == null) continue;
        groupedOffers.putIfAbsent(requestId, () => []).add(offer);
      }

      final earnings = fetchedOrders
          .where((o) => o.status == OrderStatus.delivered)
          .fold<double>(0, (sum, o) => sum + o.totalAmount);

      productCount = products.length;
      orders = fetchedOrders;
      totalEarnings = earnings;
      bulkRequests = requests;
      offersByRequest = groupedOffers;
      unreadMessagesCount =
          unreadMessages.where((m) => m['isRead'] == false).length;
      loading = false;
      bulkLoading = false;
      notifyListeners();
    } catch (_) {
      loading = false;
      bulkLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBulkRequestsAndOffers() async {
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
          final aDate =
              DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      final groupedOffers = <int, List<Map<String, dynamic>>>{};
      for (final offer in offersJson) {
        final requestId = _asInt(offer['requestId']);
        if (requestId == null) continue;
        groupedOffers.putIfAbsent(requestId, () => []).add(offer);
      }

      bulkRequests = requests;
      offersByRequest = groupedOffers;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadUnreadMessagesCount() async {
    try {
      final user = currentUser ?? await SessionService.getUser();
      if (user == null) return;
      currentUser ??= user;
      final received =
          await ApiService.getMessages(receiverId: '${user.id}');
      final unread = received
          .cast<Map<String, dynamic>>()
          .where((m) => m['isRead'] == false)
          .length;
      unreadMessagesCount = unread;
      notifyListeners();
    } catch (_) {}
  }

  void clearUnreadMessages() {
    unreadMessagesCount = 0;
    notifyListeners();
  }

  void startPolling({required bool Function() isOnMessagesTab}) {
    _loadUnreadLoop(isOnMessagesTab);
    _loadBulkLoop(isOnMessagesTab);
  }

  void _loadUnreadLoop(bool Function() isOnMessagesTab) {
    _badgeTimer?.cancel();
    _badgeTimer =
        Timer.periodic(badgePollInterval, (_) {
      if (!isOnMessagesTab()) {
        loadUnreadMessagesCount();
      }
    });
  }

  void _loadBulkLoop(bool Function() isOnMessagesTab) {
    _bulkTimer?.cancel();
    _bulkTimer =
        Timer.periodic(bulkPollInterval, (_) {
      if (!isOnMessagesTab()) {
        refreshBulkRequestsAndOffers();
      }
    });
  }

  void stopPolling() {
    _badgeTimer?.cancel();
    _bulkTimer?.cancel();
  }

  void initDailyPrices() {
    final now = DateTime.now();
    final dayKey = now.year * 10000 + now.month * 100 + now.day;
    final prevDayKey =
        now.year * 10000 + now.month * 100 + (now.day - 1);

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
      final change =
          ((todayPrice - prevPrice) / prevPrice * 100).abs();
      return {
        'name': name,
        'price': todayPrice,
        'previous': prevPrice,
        'trend': todayPrice >= prevPrice ? 'up' : 'down',
        'changePercent': change,
      };
    }).toList();

    dailyPrices = prices;
    notifyListeners();
  }

  List<Map<String, dynamic>> offersForRequest(
      Map<String, dynamic> request) {
    final requestId = _asInt(request['id']);
    if (requestId == null) return const [];
    final requestCreatedAt =
        DateTime.tryParse((request['createdAt'] ?? '').toString());
    return List<Map<String, dynamic>>.from(
            offersByRequest[requestId] ?? const [])
        .where((offer) {
          if (requestCreatedAt == null) return true;
          final offerCreatedAt =
              DateTime.tryParse((offer['createdAt'] ?? '').toString());
          if (offerCreatedAt == null) return false;
          return !offerCreatedAt.isBefore(requestCreatedAt);
        })
        .toList();
  }

  bool myOfferExists(Map<String, dynamic> request) {
    final myId = currentUser?.id;
    if (myId == null) return false;
    return offersForRequest(request)
        .any((o) => _asInt(o['farmerId']) == myId);
  }

  Future<void> submitOffer({
    required Map<String, dynamic> request,
    required double pricePerUnit,
    required double proposedQuantity,
    required String note,
  }) async {
    final user = currentUser ?? await SessionService.getUser();
    final requestId = _asInt(request['id']);
    final buyerId = _asInt(request['buyerId']);
    if (user == null || requestId == null || buyerId == null) return;

    await ApiService.createBulkOffer({
      'requestId': requestId,
      'requestCreatedAt': request['createdAt'],
      'farmerId': user.id,
      'farmerName': user.fullName,
      'pricePerUnit': pricePerUnit,
      'proposedQuantity': proposedQuantity,
      'note': note,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await ApiService.sendMessage({
      'senderId': user.id,
      'senderName': user.fullName,
      'receiverId': buyerId,
      'receiverName': request['buyerName'] ?? 'Buyer',
      'content':
          'New bulk offer sent for ${request['productName']}. Please review it.',
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await loadDashboardData();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
