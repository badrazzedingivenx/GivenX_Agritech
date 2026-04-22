import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  static const Color _primary = Color(0xFF1B5E20);

  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  int? _currentUserId;
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    try {
      final user = await SessionService.getUser();
      if (user == null) return;
      _currentUserId = user.id;
      _currentUserName = user.fullName;

      // Get all messages where this user is sender or receiver
      final sent = await ApiService.getMessages(senderId: user.id.toString());
      final received = await ApiService.getMessages(receiverId: user.id.toString());

      final allMessages = [
        ...sent.cast<Map<String, dynamic>>(),
        ...received.cast<Map<String, dynamic>>(),
      ];

      // Group by conversation partner
      final Map<int, Map<String, dynamic>> convMap = {};
      for (final msg in allMessages) {
        final senderId = msg['senderId'] as int? ?? 0;
        final receiverId = msg['receiverId'] as int? ?? 0;
        final partnerId = senderId == user.id ? receiverId : senderId;
        final partnerName = senderId == user.id
            ? (msg['receiverName'] ?? 'Unknown')
            : (msg['senderName'] ?? 'Unknown');

        if (!convMap.containsKey(partnerId) ||
            (msg['createdAt'] ?? '').compareTo(convMap[partnerId]!['lastMessageTime'] ?? '') > 0) {
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

      final convList = convMap.values.toList()
        ..sort((a, b) => (b['lastMessageTime'] ?? '').compareTo(a['lastMessageTime'] ?? ''));

      if (mounted) {
        setState(() {
          _conversations = convList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No conversations yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Start a chat from a product page', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    itemBuilder: (_, i) {
                      final conv = _conversations[i];
                      final isUnread = !(conv['isRead'] as bool? ?? true) && !(conv['isFromMe'] as bool? ?? false);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUnread ? _primary.withOpacity(0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: _primary.withOpacity(0.12),
                            child: Text(
                              (conv['partnerName'] as String? ?? '?')[0].toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 18),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv['partnerName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(conv['lastMessageTime']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnread ? _primary : Colors.grey,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              conv['lastMessage'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isUnread ? Colors.black87 : Colors.grey,
                                fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: isUnread
                              ? Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
                                )
                              : null,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  partnerId: conv['partnerId'] as int,
                                  partnerName: conv['partnerName'] as String,
                                  currentUserId: _currentUserId!,
                                  currentUserName: _currentUserName,
                                ),
                              ),
                            );
                            _loadConversations();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
