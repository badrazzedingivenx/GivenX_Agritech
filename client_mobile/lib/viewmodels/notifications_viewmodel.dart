import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_constants.dart';
import '../services/notification_badge_service.dart';

class NotificationsViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> notifications = [];

  Future<void> loadNotifications({
    required int userId,
    required String role,
  }) async {
    isLoading = true;
    notifyListeners();
    NotificationBadgeService.markAsSeen(userId);

    final items = await _fetchNotifications(userId: userId, role: role);
    notifications = items;
    isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _unwrap(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is Map && body['data'] is List) {
      return (body['data'] as List).cast<Map<String, dynamic>>();
    }
    if (body is List) return body.cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications({
    required int userId,
    required String role,
  }) async {
    final baseUrl = ApiConstants.baseUrl;
    final List<Map<String, dynamic>> results = [];
    try {
      if (role == 'Agriculteur') {
        final res = await http.get(Uri.parse('$baseUrl/orders'));
        if (res.statusCode == 200) {
          final orders = _unwrap(res);
          for (final o in orders) {
            results.add({
              'icon': Icons.shopping_cart_outlined,
              'color': const Color(0xFFE65100),
              'title': 'New Order',
              'subtitle':
                  '${o['buyerName'] ?? 'Buyer'} ordered • ${o['totalAmount']} MAD',
              'createdAt': o['createdAt'],
            });
          }
        }
        final msgRes = await http.get(Uri.parse('$baseUrl/messages'));
        if (msgRes.statusCode == 200) {
          final messages = _unwrap(msgRes);
          for (final m in messages) {
            if (m['receiverId'] == userId) {
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
      } else if (role == 'Buyer') {
        final res = await http.get(Uri.parse('$baseUrl/orders'));
        if (res.statusCode == 200) {
          final orders = _unwrap(res);
          for (final o in orders) {
            if (o['buyerId'] == userId) {
              results.add({
                'icon': Icons.receipt_long_outlined,
                'color': const Color(0xFF00695C),
                'title': 'Order Update',
                'subtitle':
                    'Order #${o['id']} • ${o['status']} • ${o['totalAmount']} MAD',
                'createdAt': o['createdAt'],
              });
            }
          }
        }
        final msgRes = await http.get(Uri.parse('$baseUrl/messages'));
        if (msgRes.statusCode == 200) {
          final messages = _unwrap(msgRes);
          for (final m in messages) {
            if (m['receiverId'] == userId) {
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
      } else if (role == 'Transporteur') {
        final res = await http.get(Uri.parse('$baseUrl/shipments'));
        if (res.statusCode == 200) {
          final shipments = _unwrap(res);
          for (final s in shipments) {
            if (s['transporterId'] == userId) {
              results.add({
                'icon': Icons.local_shipping_outlined,
                'color': const Color(0xFF6A1B9A),
                'title': 'Shipment Update',
                'subtitle':
                    'Shipment #${s['id']} • ${s['status']}',
                'createdAt': s['createdAt'],
              });
            }
          }
        }
      } else if (role == 'Banque') {
        final res = await http.get(Uri.parse('$baseUrl/financeRequests'));
        if (res.statusCode == 200) {
          final requests = _unwrap(res);
          for (final r in requests) {
            results.add({
              'icon': Icons.account_balance_outlined,
              'color': const Color(0xFF01579B),
              'title': 'Finance Request',
              'subtitle':
                  '${r['farmerName'] ?? 'Farmer'} • ${r['amount']} MAD',
              'createdAt': r['createdAt'],
            });
          }
        }
      }
    } catch (_) {}

    results.sort((a, b) =>
        (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
    return results;
  }
}
