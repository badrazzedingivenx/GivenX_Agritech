import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class RegisterViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  User? registeredUser;

  Future<User?> register(Map<String, dynamic> userData) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.registerUser(userData);
      final user = User.fromJson(result);
      await SessionService.saveSession(user);
      registeredUser = user;
      isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
