import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int partnerId;
  final String partnerName;
  final int currentUserId;
  final String currentUserName;

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _primary = Color(0xFF1B5E20);

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final sent = await ApiService.getMessages(
        senderId: '${widget.currentUserId}',
        receiverId: '${widget.partnerId}',
      );
      final received = await ApiService.getMessages(
        senderId: '${widget.partnerId}',
        receiverId: '${widget.currentUserId}',
      );
      final combined = [
        ...sent.cast<Map<String, dynamic>>(),
        ...received.cast<Map<String, dynamic>>(),
      ];

      // Mark partner -> me unread messages as read.
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

      combined.sort((a, b) => (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? ''));
      if (mounted) {
        setState(() {
          _messages = combined;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    // Optimistic update
    setState(() {
      _messages.add({
        'senderId': widget.currentUserId,
        'senderName': widget.currentUserName,
        'receiverId': widget.partnerId,
        'receiverName': widget.partnerName,
        'content': text,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    try {
      await ApiService.sendMessage({
        'senderId': widget.currentUserId,
        'senderName': widget.currentUserName,
        'receiverId': widget.partnerId,
        'receiverName': widget.partnerName,
        'content': text,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _primary.withOpacity(0.12),
              child: Text(
                widget.partnerName.isNotEmpty ? widget.partnerName[0].toUpperCase() : '?',
                style: TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.partnerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Text('Online', style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hello!', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMe = msg['senderId'] == widget.currentUserId;
                          return _buildBubble(msg['content'] ?? '', isMe, _formatTime(msg['createdAt']));
                        },
                      ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? _primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
