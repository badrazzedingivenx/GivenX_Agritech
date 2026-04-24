import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class NotificationBadgeService {

  static String _prefsKey(int userId) => 'notif_last_seen_$userId';

  static Future<DateTime?> getLastSeen(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey(userId));
    if (stored == null) return null;
    return DateTime.tryParse(stored);
  }

  static Future<void> markAsSeen(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(userId), DateTime.now().toIso8601String());
  }

  static List<dynamic> _unwrap(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is Map && body['data'] is List) return body['data'] as List;
    if (body is List) return body;
    return [];
  }

  static Future<int> fetchBadgeCount(String role, int userId) async {
    try {
      final lastSeen = await getLastSeen(userId) ??
          DateTime.now().subtract(const Duration(days: 7));

      int count = 0;
      final base = ApiConstants.baseUrl;

      if (role == 'Agriculteur') {
        final res = await http.get(Uri.parse('$base/orders'));
        if (res.statusCode == 200) {
          final orders = _unwrap(res);
          count += orders.where((o) {
            final farmerId = o['farmerId'];
            final createdAt = DateTime.tryParse(o['createdAt'] ?? '');
            return farmerId == userId &&
                createdAt != null &&
                createdAt.isAfter(lastSeen);
          }).length;
        }
        final msgRes = await http.get(Uri.parse('$base/messages'));
        if (msgRes.statusCode == 200) {
          final messages = _unwrap(msgRes);
          count += messages.where((m) {
            final receiverId = m['receiverId'];
            final createdAt = DateTime.tryParse(m['createdAt'] ?? '');
            return receiverId == userId &&
                createdAt != null &&
                createdAt.isAfter(lastSeen);
          }).length;
        }
      } else if (role == 'Buyer') {
        final res = await http.get(Uri.parse('$base/orders'));
        if (res.statusCode == 200) {
          final orders = _unwrap(res);
          count += orders.where((o) {
            final buyerId = o['buyerId'];
            final createdAt = DateTime.tryParse(o['createdAt'] ?? '');
            return buyerId == userId &&
                createdAt != null &&
                createdAt.isAfter(lastSeen);
          }).length;
        }
      } else if (role == 'Transporteur') {
        final res = await http.get(Uri.parse('$base/shipments'));
        if (res.statusCode == 200) {
          final shipments = _unwrap(res);
          count += shipments.where((s) {
            final createdAt = DateTime.tryParse(s['createdAt'] ?? '');
            return createdAt != null && createdAt.isAfter(lastSeen);
          }).length;
        }
      } else if (role == 'Banque') {
        final res = await http.get(Uri.parse('$base/payments'));
        if (res.statusCode == 200) {
          final payments = _unwrap(res);
          count += payments.where((p) {
            final createdAt = DateTime.tryParse(p['createdAt'] ?? '');
            return createdAt != null && createdAt.isAfter(lastSeen);
          }).length;
        }
      }

      return count;
    } catch (_) {
      return 0;
    }
  }
}
