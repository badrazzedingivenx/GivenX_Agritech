import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class UsineDashboardViewModel extends ChangeNotifier {
  static const Duration badgePollInterval = Duration(seconds: 10);

  int unreadMessagesCount = 0;
  int? currentUserId;
  Timer? _badgeTimer;

  Future<void> init() async {
    final user = await SessionService.getUser();
    currentUserId = user?.id;
    await loadUnreadMessagesCount();
    startPolling();
  }

  Future<void> loadUnreadMessagesCount() async {
    try {
      final user = await SessionService.getUser();
      if (user == null) return;
      currentUserId ??= user.id;
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

  void startPolling() {
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(badgePollInterval, (_) {
      loadUnreadMessagesCount();
    });
  }

  void stopPolling() {
    _badgeTimer?.cancel();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
