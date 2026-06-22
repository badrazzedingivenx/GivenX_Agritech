import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../models/finance_request.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class BanqueDashboardViewModel extends ChangeNotifier {
  bool loading = true;
  bool financeLoading = true;
  List<Payment> payments = [];
  List<FinanceRequest> financeRequests = [];
  int? currentUserId;

  // Stats
  double get totalPayments =>
      payments.fold(0.0, (sum, p) => sum + p.amount);

  int get pendingFinanceCount => financeRequests
      .where((r) => r.status.toLowerCase() == 'pending')
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
      financeRequests = data
          .map((e) => FinanceRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      financeRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
