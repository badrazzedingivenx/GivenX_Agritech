import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

/// Drives the admin "Orders Supervision" screen: lists every order on the
/// platform (not scoped to a buyer) and lets the admin override a stuck
/// order's status via PATCH /orders/:id.
class AdminOrdersViewModel extends ChangeNotifier {
  bool loading = true;
  String? error;

  /// When null, all orders are shown. Otherwise only orders with this status.
  OrderStatus? statusFilter;

  /// Ids currently being updated, used to disable controls while in-flight.
  final Set<int> updating = {};

  List<Order> _orders = [];

  List<Order> get orders {
    final list = statusFilter == null
        ? _orders
        : _orders.where((o) => o.status == statusFilter).toList();
    return list;
  }

  int countFor(OrderStatus status) =>
      _orders.where((o) => o.status == status).length;

  int get totalCount => _orders.length;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await ApiService.getOrders();
      _orders = raw
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      loading = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load orders';
      loading = false;
      notifyListeners();
    }
  }

  void setFilter(OrderStatus? status) {
    statusFilter = status;
    notifyListeners();
  }

  /// Admin override of an order's status. Unlike the buyer/farmer flows this
  /// is not constrained by the normal lifecycle transitions, so a stuck
  /// order can be moved or cancelled directly.
  Future<bool> updateStatus(Order order, OrderStatus status) async {
    final id = order.id;
    if (id == null || order.status == status) return false;
    updating.add(id);
    notifyListeners();
    try {
      await ApiService.updateOrder(id, {
        'status': status.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final i = _orders.indexWhere((o) => o.id == id);
      if (i != -1) {
        _orders[i] = _orders[i].copyWith(status: status, updatedAt: DateTime.now());
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      updating.remove(id);
      notifyListeners();
    }
  }
}
