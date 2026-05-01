import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/conversations_viewmodel.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConversationsViewModel>(
      create: (_) => ConversationsViewModel()..loadConversations(),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  const _ConversationsView();

  static const Color _primary = Color(0xFF1B5E20);

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
    final vm = context.watch<ConversationsViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.conversations.isEmpty
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
                  onRefresh: vm.loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: vm.conversations.length,
                    itemBuilder: (_, i) {
                      final conv = vm.conversations[i];
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
                              (() { final n = conv['partnerName'] as String? ?? ''; return n.isNotEmpty ? n[0].toUpperCase() : '?'; })(),
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
                                  currentUserId: vm.currentUserId!,
                                  currentUserName: vm.currentUserName,
                                ),
                              ),
                            );
                            vm.loadConversations();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
