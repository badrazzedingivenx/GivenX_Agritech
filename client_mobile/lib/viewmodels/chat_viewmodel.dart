import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> messages = [];

  Future<void> loadMessages({
    required int currentUserId,
    required int partnerId,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final sent = await ApiService.getMessages(
        senderId: '$currentUserId',
        receiverId: '$partnerId',
      );
      final received = await ApiService.getMessages(
        senderId: '$partnerId',
        receiverId: '$currentUserId',
      );
      final combined = [
        ...sent.cast<Map<String, dynamic>>(),
        ...received.cast<Map<String, dynamic>>(),
      ];

      // Mark incoming unread messages as read
      final unreadIncoming = received
          .cast<Map<String, dynamic>>()
          .where((m) => (m['isRead'] ?? false) == false)
          .toList();
      for (final msg in unreadIncoming) {
        final id = msg['id'];
        if (id is int) {
          await ApiService.updateMessage(id, {'isRead': true});
          msg['isRead'] = true;
        }
      }

      combined.sort((a, b) =>
          (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? ''));
      messages = combined;
      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required int currentUserId,
    required String currentUserName,
    required int partnerId,
    required String partnerName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    try {
      final newMsg = await ApiService.sendMessage({
        'senderId': currentUserId,
        'senderName': currentUserName,
        'receiverId': partnerId,
        'receiverName': partnerName,
        'content': text.trim(),
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      messages = [...messages, newMsg];
      notifyListeners();
    } catch (_) {}
  }
}
