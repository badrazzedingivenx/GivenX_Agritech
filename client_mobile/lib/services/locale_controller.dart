import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global locale controller — any widget can change the app locale
/// without needing access to the root widget's setState.
class LocaleController {
  LocaleController._();

  static final ValueNotifier<Locale?> notifier = ValueNotifier<Locale?>(null);

  /// Call once in [AgriFlowApp.initState] to restore the saved locale.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('preferred_locale');
    if (code != null && code.isNotEmpty) {
      notifier.value = Locale(code);
    }
  }

  /// Persists and applies a new locale immediately across the whole app.
  static Future<void> setLocale(String langCode, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_locale', langCode);
    await prefs.setString('preferred_language', displayName);
    notifier.value = Locale(langCode);
  }

  static Future<String> currentLanguageDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('preferred_language') ?? 'English';
  }
}
