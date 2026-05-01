import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class AuthViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? emailError;
  String? passwordError;
  String? errorMessage;
  User? loggedInUser;

  void clearErrors() {
    emailError = null;
    passwordError = null;
    errorMessage = null;
    notifyListeners();
  }

  void setEmailError(String? error) {
    emailError = error;
    notifyListeners();
  }

  void setPasswordError(String? error) {
    passwordError = error;
    notifyListeners();
  }

  bool validateInputs({required String email, required String password}) {
    emailError = null;
    passwordError = null;

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    bool valid = true;
    if (email.isEmpty) {
      emailError = 'Email is required';
      valid = false;
    } else if (!emailRegex.hasMatch(email)) {
      emailError = 'Email is invalid';
      valid = false;
    }

    if (password.isEmpty) {
      passwordError = 'Password is required';
      valid = false;
    }

    notifyListeners();
    return valid;
  }

  Future<User?> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);
      final userData = result['user'] as Map<String, dynamic>;
      final token = result['token'] as String?;
      if (token != null) {
        userData['token'] = token;
      }
      final user = User.fromJson(userData);
      await SessionService.saveSession(user);
      loggedInUser = user;
      isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      isLoading = false;
      final errorStr = e.toString();
      if (errorStr.contains('401')) {
        errorMessage = 'invalid_credentials';
      } else {
        errorMessage = 'Connection error: $e';
      }
      notifyListeners();
      return null;
    }
  }
}
