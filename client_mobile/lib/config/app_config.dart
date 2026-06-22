/// Central application configuration.
///
/// All network configuration lives here. To point the app at a different
/// backend (local emulator, a LAN IP for real-device testing, or a deployed
/// server) change [host]/[port] in one place — no IP addresses should be
/// hardcoded anywhere else in the codebase.
class AppConfig {
  AppConfig._();

  /// Backend host.
  /// - Web / iOS simulator / desktop: `localhost`
  /// - Android emulator: `10.0.2.2`
  /// - Real device: set this to your machine's LAN IP (e.g. `192.168.x.x`)
  static const String host = 'localhost';

  /// Backend port (json-server default).
  static const int port = 3000;

  /// Fully-qualified API base URL used across the app.
  static const String baseUrl = 'http://$host:$port/api';
}
