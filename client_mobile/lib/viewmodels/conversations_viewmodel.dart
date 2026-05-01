import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class ConversationsViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> conversations = [];
  int? currentUserId;
  String currentUserName = '';

  Future<void> loadConversations() async {
    isLoading = true;
    notifyListeners();
    try {
      final user = await SessionService.getUser();
      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }
      currentUserId = user.id;
      currentUserName = user.fullName;

      final sent = await ApiService.getMessages(senderId: user.id.toString());
      final received =
          await ApiService.getMessages(receiverId: user.id.toString());

      final allMessages = [
        ...sent.cast<Map<String, dynamic>>(),
        ...received.cast<Map<String, dynamic>>(),
      ];

      final Map<int, Map<String, dynamic>> convMap = {};
      for (final msg in allMessages) {
        final senderId = msg['senderId'] as int? ?? 0;
        final receiverId = msg['receiverId'] as int? ?? 0;
        final partnerId =
            senderId == user.id ? receiverId : senderId;
        final partnerName = senderId == user.id
            ? (msg['receiverName'] ?? 'Unknown')
            : (msg['senderName'] ?? 'Unknown');

        if (!convMap.containsKey(partnerId) ||
            (msg['createdAt'] ?? '')
                    .compareTo(convMap[partnerId]!['lastMessageTime'] ?? '') >
                0) {
          convMap[partnerId] = {
            'partnerId': partnerId,
            'partnerName': partnerName,
            'lastMessage': msg['content'] ?? '',
            'lastMessageTime': msg['createdAt'] ?? '',
            'isRead': msg['isRead'] ?? true,
            'isFromMe': senderId == user.id,
          };
        }
      }

      final convList = convMap.values
          .where((c) =>
              (c['partnerId'] as int? ?? 0) != 0 &&
              (c['partnerName'] as String? ?? '').isNotEmpty)
          .toList()
        ..sort((a, b) =>
            (b['lastMessageTime'] ?? '')
                .compareTo(a['lastMessageTime'] ?? ''));

      conversations = convList;
      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }
}
