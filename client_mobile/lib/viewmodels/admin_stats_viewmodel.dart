import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/shipment.dart';
import '../models/finance_request.dart';
import '../services/api_service.dart';

/// Aggregates platform-wide KPIs for the admin Statistics dashboard.
/// Pulls from /users, /orders, /shipments and /financeRequests.
class AdminStatsViewModel extends ChangeNotifier {
  bool loading = true;
  String? error;

  List<User> users = [];
  List<Order> orders = [];
  List<Shipment> shipments = [];
  List<FinanceRequest> financeRequests = [];

  // ─── User KPIs ─────────────────────────────────────────
  int get totalUsers => users.length;
  int countByRole(UserRole role) =>
      users.where((u) => u.role == role).length;
  int get farmerCount => countByRole(UserRole.farmer);
  int get buyerCount => countByRole(UserRole.buyer);
  int get transporterCount => countByRole(UserRole.transporter);
  int get bankCount => countByRole(UserRole.bank);
  int get pendingUsers =>
      users.where((u) => u.status == UserStatus.pending).length;

  // ─── Activity KPIs ─────────────────────────────────────
  int get totalOrders => orders.length;
  int get totalShipments => shipments.length;
  int get totalFinanceRequests => financeRequests.length;

  double get totalRevenue => orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  int orderCountByStatus(OrderStatus status) =>
      orders.where((o) => o.status == status).length;

  int financeCountByStatus(String status) =>
      financeRequests.where((f) => f.status.toLowerCase() == status).length;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApiService.getUsers(),
        ApiService.getOrders(),
        ApiService.getShipments(),
        ApiService.getFinanceRequests(),
      ]);
      users = results[0]
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      orders = results[1]
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      shipments = results[2]
          .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
          .toList();
      financeRequests = results[3]
          .map((e) => FinanceRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      loading = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load statistics';
      loading = false;
      notifyListeners();
    }
  }
}
