import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/notification_badge_service.dart';
import '../../../services/api_constants.dart';

class NotificationsScreen extends StatefulWidget {
  final String role;
  final int userId;

  const NotificationsScreen({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static String get _baseUrl => ApiConstants.baseUrl;
  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _bgColor = Color(0xFFF4F9F3);

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  static const int _previewCount = 5;

  @override
  void initState() {
    super.initState();
    NotificationBadgeService.markAsSeen(widget.userId);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final items = await _fetchNotifications();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _unwrap(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is Map && body['data'] is List) {
      return (body['data'] as List).cast<Map<String, dynamic>>();
    }
    if (body is List) return body.cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final List<Map<String, dynamic>> results = [];
    try {
      if (widget.role == 'Agriculteur') {
        final res = await http.get(Uri.parse('$_baseUrl/orders'));
        if (res.statusCode == 200) {
          final orders = _unwrap(res);
          for (final o in orders) {
            // farmerId may be null in some orders — show all orders as
            // notifications for farmer (they originated a product listing)
            results.add({
              'icon': Icons.shopping_cart_outlined,
              'color': const Color(0xFFE65100),
              'title': 'New Order',
              'subtitle': '${o['buyerName'] ?? 'Buyer'} ordered • ${o['totalAmount']} MAD',
              'createdAt': o['createdAt'],
            });
          }
        }
        final msgRes = await http.get(Uri.parse('$_baseUrl/messages'));
        if (msgRes.statusCode == 200) {
          final messages = _unwrap(msgRes);
          for (final m in messages) {
            if (m['receiverId'] == widget.userId) {
              results.add({
                'icon': Icons.chat_bubble_outline,
                'color': const Color(0xFF1565C0),
                'title': 'New Message',
                'subtitle': '${m['senderName']}: ${m['content']}',
                'createdAt': m['createdAt'],
              });
            }
          }
        }
      } else if (widget.role == 'Buyer') {
        final res = await http.get(Uri.parse('$_baseUrl/orders'));
        if (res.statusCode == 200) {
          final orders = _unwrap(res);
          for (final o in orders) {
            if (o['buyerId'] == widget.userId) {
              results.add({
                'icon': Icons.receipt_long_outlined,
                'color': const Color(0xFF00695C),
                'title': 'Order Update',
                'subtitle': 'Order #${o['id']} • ${o['status']} • ${o['totalAmount']} MAD',
                'createdAt': o['createdAt'],
              });
            }
          }
        }
        final msgRes = await http.get(Uri.parse('$_baseUrl/messages'));
        if (msgRes.statusCode == 200) {
          final messages = _unwrap(msgRes);
          for (final m in messages) {
            if (m['receiverId'] == widget.userId) {
              results.add({
                'icon': Icons.chat_bubble_outline,
                'color': const Color(0xFF1565C0),
                'title': 'New Message',
                'subtitle': '${m['senderName']}: ${m['content']}',
                'createdAt': m['createdAt'],
              });
            }
          }
        }
      } else if (widget.role == 'Transporteur') {
        final res = await http.get(Uri.parse('$_baseUrl/shipments'));
        if (res.statusCode == 200) {
          final shipments = _unwrap(res);
          for (final s in shipments) {
            results.add({
              'icon': Icons.local_shipping_outlined,
              'color': const Color(0xFF283593),
              'title': 'Shipment Request',
              'subtitle': '${s['pickupLocation']} → ${s['deliveryLocation']} • ${s['status']}',
              'createdAt': s['createdAt'],
            });
          }
        }
      } else if (widget.role == 'Banque') {
        final res = await http.get(Uri.parse('$_baseUrl/payments'));
        if (res.statusCode == 200) {
          final payments = _unwrap(res);
          for (final p in payments) {
            results.add({
              'icon': Icons.account_balance_outlined,
              'color': const Color(0xFF6A1B9A),
              'title': 'Payment',
              'subtitle': '${p['buyerName']} • ${p['amount']} MAD • ${p['status']}',
              'createdAt': p['createdAt'],
            });
          }
        }
      }

      results.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
    } catch (_) {}
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1A3C34),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryGreen))
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final preview = _items.take(_previewCount).toList();
    final remaining = _items.length - _previewCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...preview.map((item) => _buildCard(item)),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _AllNotificationsScreen(items: _items),
                  ),
                );
              },
              child: Text(
                'See all $remaining more notifications →',
                style: const TextStyle(
                  color: _primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final color = (item['color'] as Color?) ?? _primaryGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A3C34),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['subtitle'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item['createdAt'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDate(item['createdAt'] as String),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AllNotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _AllNotificationsScreen({required this.items});

  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _bgColor = Color(0xFFF4F9F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'All Notifications',
          style: TextStyle(
            color: Color(0xFF1A3C34),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCard(items[index]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final color = (item['color'] as Color?) ?? _primaryGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A3C34),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['subtitle'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item['createdAt'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDate(item['createdAt'] as String),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
