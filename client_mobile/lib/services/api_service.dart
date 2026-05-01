import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiService {
  // ─── Helpers ───────────────────────────────────────────

  static dynamic _unwrap(dynamic body) {
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  static Future<List<dynamic>> _getList(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return _unwrap(jsonDecode(response.body)) as List<dynamic>;
    }
    throw Exception('GET $url failed (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> _post(String url, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _unwrap(jsonDecode(response.body)) as Map<String, dynamic>;
    }
    throw Exception('POST $url failed (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> _patch(String url, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return _unwrap(jsonDecode(response.body)) as Map<String, dynamic>;
    }
    throw Exception('PATCH $url failed (${response.statusCode})');
  }

  static Future<void> _delete(String url) async {
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('DELETE $url failed (${response.statusCode})');
    }
  }

  // ─── Auth ──────────────────────────────────────────────

  static Future<List<dynamic>> getUsers({String? email, String? password}) async {
    String url = ApiConstants.users;
    if (email != null && password != null) {
      url += '?email=$email&password=$password';
    }
    return _getList(url);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    return _post(ApiConstants.login, {'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    print('[RegisterUser] Payload: $userData');
    return _post(ApiConstants.users, userData);
  }

  static Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.users}/$id', data);
  }

  static Future<void> deleteUser(int id) async {
    return _delete('${ApiConstants.users}/$id');
  }

  static Future<Map<String, dynamic>> getUserById(int id) async {
    final response = await http.get(Uri.parse('${ApiConstants.users}/$id'));
    if (response.statusCode == 200) {
      return _unwrap(jsonDecode(response.body)) as Map<String, dynamic>;
    }
    throw Exception('GET user/$id failed (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> createSupportTicket(Map<String, dynamic> data) async {
    return _post('${ApiConstants.baseUrl}/supportTickets', data);
  }

  static Future<List<dynamic>> getRoles() async {
    return _getList(ApiConstants.roles);
  }

  static Future<List<dynamic>> getBanks() async {
    return _getList(ApiConstants.banks);
  }

  // ─── Products ──────────────────────────────────────────

  static Future<List<dynamic>> getProducts({String? sellerId}) async {
    String url = ApiConstants.products;
    if (sellerId != null) url += '?farmerId=$sellerId';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    return _post(ApiConstants.products, data);
  }

  static Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.products}/$id', data);
  }

  static Future<void> deleteProduct(int id) async {
    return _delete('${ApiConstants.products}/$id');
  }

  // ─── Orders ────────────────────────────────────────────

  static Future<List<dynamic>> getOrders({String? buyerId, String? farmerId}) async {
    String url = ApiConstants.orders;
    final params = <String>[];
    if (buyerId != null) params.add('buyerId=$buyerId');
    if (farmerId != null) params.add('farmerId=$farmerId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    return _post(ApiConstants.orders, data);
  }

  static Future<Map<String, dynamic>> updateOrder(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.orders}/$id', data);
  }

  // ─── Shipments ─────────────────────────────────────────

  static Future<List<dynamic>> getShipments({String? transporterId, String? orderId}) async {
    String url = ApiConstants.shipments;
    final params = <String>[];
    if (transporterId != null) params.add('transporterId=$transporterId');
    if (orderId != null) params.add('orderId=$orderId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> createShipment(Map<String, dynamic> data) async {
    return _post(ApiConstants.shipments, data);
  }

  static Future<Map<String, dynamic>> updateShipment(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.shipments}/$id', data);
  }

  // ─── Messages ──────────────────────────────────────────

  static Future<List<dynamic>> getMessages({String? senderId, String? receiverId}) async {
    String url = ApiConstants.messages;
    final params = <String>[];
    if (senderId != null) params.add('senderId=$senderId');
    if (receiverId != null) params.add('receiverId=$receiverId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
    return _post(ApiConstants.messages, data);
  }

  static Future<Map<String, dynamic>> updateMessage(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.messages}/$id', data);
  }

  // ─── Payments ──────────────────────────────────────────

  static Future<List<dynamic>> getPayments({String? orderId, String? userId}) async {
    String url = ApiConstants.payments;
    final params = <String>[];
    if (orderId != null) params.add('orderId=$orderId');
    if (userId != null) params.add('userId=$userId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    return _post(ApiConstants.payments, data);
  }

  static Future<Map<String, dynamic>> updatePayment(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.payments}/$id', data);
  }

  // ─── Bulk sourcing ────────────────────────────────────

  static Future<List<dynamic>> getBulkRequests({
    String? buyerId,
    String? buyerType,
    String? status,
  }) async {
    String url = ApiConstants.bulkRequests;
    final params = <String>[];
    if (buyerId != null) params.add('buyerId=$buyerId');
    if (buyerType != null) params.add('buyerType=$buyerType');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> createBulkRequest(Map<String, dynamic> data) async {
    return _post(ApiConstants.bulkRequests, data);
  }

  static Future<Map<String, dynamic>> updateBulkRequest(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.bulkRequests}/$id', data);
  }

  static Future<List<dynamic>> getBulkOffers({
    String? requestId,
    String? status,
  }) async {
    String url = ApiConstants.bulkOffers;
    final params = <String>[];
    if (requestId != null) params.add('requestId=$requestId');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> createBulkOffer(Map<String, dynamic> data) async {
    return _post(ApiConstants.bulkOffers, data);
  }

  static Future<Map<String, dynamic>> updateBulkOffer(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.bulkOffers}/$id', data);
  }

  // ─── Reviews ───────────────────────────────────────────

  static Future<List<dynamic>> getReviews({String? targetUserId, String? reviewerId}) async {
    String url = ApiConstants.reviews;
    final params = <String>[];
    if (targetUserId != null) params.add('targetUserId=$targetUserId');
    if (reviewerId != null) params.add('reviewerId=$reviewerId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> createReview(Map<String, dynamic> data) async {
    return _post(ApiConstants.reviews, data);
  }

  static Future<void> deleteReview(int id) async {
    return _delete('${ApiConstants.reviews}/$id');
  }

  // ─── Finance Requests ─────────────────────────────────────────────

  static Future<List<dynamic>> getFinanceRequests({String? farmerId, String? status}) async {
    String url = ApiConstants.financeRequests;
    final params = <String>[];
    if (farmerId != null) params.add('farmerId=$farmerId');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return _getList(url);
  }

  static Future<Map<String, dynamic>> createFinanceRequest(Map<String, dynamic> data) async {
    return _post(ApiConstants.financeRequests, data);
  }

  static Future<Map<String, dynamic>> updateFinanceRequest(int id, Map<String, dynamic> data) async {
    return _patch('${ApiConstants.financeRequests}/$id', data);
  }

  static Future<void> deleteFinanceRequest(int id) async {
    return _delete('${ApiConstants.financeRequests}/$id');
  }
}
