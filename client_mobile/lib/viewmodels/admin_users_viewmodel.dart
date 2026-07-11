import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// Drives the admin "User Validation" screen: loads users, lets the admin
/// filter by [UserStatus] and approve/reject (block) accounts via
/// PATCH /users/:id.
class AdminUsersViewModel extends ChangeNotifier {
  bool loading = true;
  String? error;

  /// When null, all users are shown. Otherwise only users with this status.
  UserStatus? statusFilter;

  /// Ids currently being updated, used to disable buttons while in-flight.
  final Set<int> updating = {};

  List<User> _users = [];

  List<User> get users {
    if (statusFilter == null) return _users;
    return _users.where((u) => u.status == statusFilter).toList();
  }

  int countFor(UserStatus status) =>
      _users.where((u) => u.status == status).length;

  int get totalCount => _users.length;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await ApiService.getUsers();
      _users = raw
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      loading = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load users';
      loading = false;
      notifyListeners();
    }
  }

  void setFilter(UserStatus? status) {
    statusFilter = status;
    notifyListeners();
  }

  /// Approve a pending/blocked account → status = active.
  Future<bool> approve(User user) => _updateStatus(user, UserStatus.active);

  /// Reject/block an account → status = blocked.
  Future<bool> reject(User user) => _updateStatus(user, UserStatus.blocked);

  Future<bool> _updateStatus(User user, UserStatus status) async {
    final id = user.id;
    if (id == null) return false;
    updating.add(id);
    notifyListeners();
    try {
      await ApiService.updateUser(id, {'status': status.toJson()});
      final i = _users.indexWhere((u) => u.id == id);
      if (i != -1) _users[i] = _users[i].copyWith(status: status);
      return true;
    } catch (_) {
      return false;
    } finally {
      updating.remove(id);
      notifyListeners();
    }
  }
}
