import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  bool loading = true;
  int? currentUserId;

  List<User> users = [];
  List<Product> products = [];
  List<Order> orders = [];

  int get userCount => users.length;
  int get productCount => products.length;
  int get orderCount => orders.length;
  double get totalRevenue => orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    try {
      final user = await SessionService.getUser();
      currentUserId = user?.id;
      final results = await Future.wait([
        ApiService.getUsers(),
        ApiService.getProducts(),
        ApiService.getOrders(),
      ]);
      users = (results[0] as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      products = (results[1] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      orders = (results[2] as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      loading = false;
      notifyListeners();
    } catch (_) {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(int id) async {
    await ApiService.deleteUser(id);
    users.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await ApiService.deleteProduct(id);
    products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> logout() async {
    await SessionService.clearSession();
  }
}
