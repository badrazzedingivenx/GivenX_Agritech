import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/finance_request.dart';
import '../services/api_service.dart';

/// Drives the admin "Finance Requests Overview" screen: lists every finance
/// request with its status, the requesting agriculteur and the assigned
/// établissement de financement (resolved from the reviewer's bank account).
class AdminFinanceViewModel extends ChangeNotifier {
  bool loading = true;
  String? error;

  /// When null, all requests are shown. Otherwise filtered by status string
  /// (pending / reviewing / approved / rejected).
  String? statusFilter;

  List<FinanceRequest> _requests = [];

  /// Maps a bank user id → display name, to resolve the assigned établissement.
  final Map<String, String> _bankNames = {};

  List<FinanceRequest> get requests {
    if (statusFilter == null) return _requests;
    return _requests
        .where((r) => r.status.toLowerCase() == statusFilter)
        .toList();
  }

  int get totalCount => _requests.length;

  int countFor(String status) =>
      _requests.where((r) => r.status.toLowerCase() == status).length;

  /// Display name of the établissement assigned to a request, or null.
  String? bankNameFor(FinanceRequest r) {
    final id = r.reviewedBy;
    if (id == null || id.isEmpty) return null;
    return _bankNames[id];
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApiService.getFinanceRequests(),
        ApiService.getUsers(),
      ]);
      _requests = results[0]
          .map((e) => FinanceRequest.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _bankNames.clear();
      for (final raw in results[1]) {
        final user = User.fromJson(raw as Map<String, dynamic>);
        if (user.role == UserRole.bank && user.id != null) {
          final name = (user.bankName != null && user.bankName!.isNotEmpty)
              ? user.bankName!
              : (user.fullName.isNotEmpty ? user.fullName : user.email);
          _bankNames['${user.id}'] = name;
        }
      }
      loading = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load finance requests';
      loading = false;
      notifyListeners();
    }
  }

  void setFilter(String? status) {
    statusFilter = status;
    notifyListeners();
  }
}
