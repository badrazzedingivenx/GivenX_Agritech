import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class BanqueDashboardViewModel extends ChangeNotifier {
  bool loading = true;
  bool financeLoading = true;
  List<Payment> payments = [];
  List<Map<String, dynamic>> financeRequests = [];
  int? currentUserId;

  // Stats
  double get totalPayments =>
      payments.fold(0.0, (sum, p) => sum + p.amount);

  int get pendingFinanceCount => financeRequests
      .where((r) =>
          (r['status'] ?? '').toString().toLowerCase() == 'pending')
      .length;

  Future<void> loadAll() async {
    await Future.wait([loadPayments(), loadFinanceRequests()]);
  }

  Future<void> loadPayments() async {
    try {
      final user = await SessionService.getUser();
      currentUserId = user?.id;
      final data = await ApiService.getPayments();
      payments = data
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();
      loading = false;
      notifyListeners();
    } catch (_) {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadFinanceRequests() async {
    try {
      final data = await ApiService.getFinanceRequests();
      financeRequests = data.cast<Map<String, dynamic>>();
      financeRequests.sort((a, b) {
        final aDate =
            DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      financeLoading = false;
      notifyListeners();
    } catch (_) {
      financeLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveFinanceRequest(int id) async {
    await ApiService.updateFinanceRequest(id, {'status': 'approved'});
    await loadFinanceRequests();
  }

  Future<void> rejectFinanceRequest(int id) async {
    await ApiService.updateFinanceRequest(id, {'status': 'rejected'});
    await loadFinanceRequests();
  }
}
