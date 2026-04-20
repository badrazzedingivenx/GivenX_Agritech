import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiService {
  static Future<List<dynamic>> getUsers({String? email, String? password}) async {
    String url = ApiConstants.users;
    if (email != null && password != null) {
      url += '?email=$email&password=$password';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'] as List<dynamic>;
      }
      return body as List<dynamic>;
    }
    throw Exception('Failed to fetch users');
  }

  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse(ApiConstants.users),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'] as Map<String, dynamic>;
      }
      return body as Map<String, dynamic>;
    }
    throw Exception('Failed to register user');
  }

  static Future<List<dynamic>> getRoles() async {
    final response = await http.get(Uri.parse(ApiConstants.roles));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'] as List<dynamic>;
      }
      return body as List<dynamic>;
    }
    throw Exception('Failed to fetch roles');
  }

  static Future<List<dynamic>> getBanks() async {
    final response = await http.get(Uri.parse(ApiConstants.banks));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'] as List<dynamic>;
      }
      return body as List<dynamic>;
    }
    throw Exception('Failed to fetch banks');
  }
}
