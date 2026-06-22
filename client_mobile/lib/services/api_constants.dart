import '../config/app_config.dart';

/// REST endpoint constants. The base URL comes from [AppConfig.baseUrl];
/// there are no hardcoded IP addresses here.
class ApiConstants {
  static const String baseUrl = AppConfig.baseUrl;

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String users = '$baseUrl/users';
  static const String roles = '$baseUrl/roles';
  static const String banks = '$baseUrl/banks';

  // Products
  static const String products = '$baseUrl/products';

  // Orders
  static const String orders = '$baseUrl/orders';

  // Shipments
  static const String shipments = '$baseUrl/shipments';

  // Messages
  static const String messages = '$baseUrl/messages';

  // Payments
  static const String payments = '$baseUrl/payments';

  // Bulk sourcing
  static const String bulkRequests = '$baseUrl/bulkRequests';
  static const String bulkOffers = '$baseUrl/bulkOffers';

  // Reviews
  static const String reviews = '$baseUrl/reviews';

  // Finance Requests
  static const String financeRequests = '$baseUrl/financeRequests';
}
