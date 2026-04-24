import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class ApiConstants {
  // ── Change this to your PC's local WiFi IP for real-device testing ──
  static const String _localIp = '192.168.8.83'; // ← IP ديالك في الشبكة WiFi

  static const int _port = 3000;

  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    String host;
    if (kIsWeb) {
      host = 'localhost';
    } else if (Platform.isAndroid) {
      // Real device vs emulator: emulator has 'generic' or 'sdk' in model/fingerprint.
      // However, dart:io can't read Build props, so we use a simple heuristic:
      // the emulator resolves 10.0.2.2 → host loopback.
      // For safety we check the ANDROID_EMULATOR env var set by the emulator,
      // but the most reliable approach is: if running a debug build on Android,
      // try 10.0.2.2; for profile/release (APK installs), use the local IP.
      final isEmulator = const bool.fromEnvironment('dart.vm.product') == false &&
          _isLikelyEmulator();
      host = isEmulator ? '10.0.2.2' : _localIp;
    } else {
      // iOS simulator, macOS, Linux, Windows desktop
      host = 'localhost';
    }

    final url = 'http://$host:$_port/api';
    debugPrint('┌─────────────────────────────────────');
    debugPrint('│ ApiConstants baseUrl = $url');
    debugPrint('│ Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    debugPrint('└─────────────────────────────────────');
    return url;
  }

  /// Heuristic: Android emulators typically have 'sdk' or 'generic' in the
  /// product/hardware string exposed via environment or a loopback test.
  /// A simple and reliable check: in debug mode on Android, the emulator
  /// sets certain system properties. We default to emulator for debug builds
  /// and real device for release (APK) builds.
  static bool _isLikelyEmulator() {
    // Release / profile builds are always APK installs → real device
    if (const bool.fromEnvironment('dart.vm.product')) return false;
    // In debug, assume emulator. If you debug on a real device via USB,
    // temporarily change _localIp or flip this to false.
    return true;
  }

  // Auth
  static final String login = '$baseUrl/auth/login';
  static final String users = '$baseUrl/users';
  static final String roles = '$baseUrl/roles';
  static final String banks = '$baseUrl/banks';

  // Products
  static final String products = '$baseUrl/products';

  // Orders
  static final String orders = '$baseUrl/orders';

  // Shipments
  static final String shipments = '$baseUrl/shipments';

  // Messages
  static final String messages = '$baseUrl/messages';

  // Payments
  static final String payments = '$baseUrl/payments';

  // Bulk sourcing
  static final String bulkRequests = '$baseUrl/bulkRequests';
  static final String bulkOffers = '$baseUrl/bulkOffers';

  // Reviews
  static final String reviews = '$baseUrl/reviews';

  // Finance Requests
  static final String financeRequests = '$baseUrl/financeRequests';
}
