// lib/presentation/navigation/app_router.dart
import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/login_screen.dart';
import '../screens/products/products_page.dart';
import '../screens/orders/buyer_orders_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_statistics_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/admin_finance_screen.dart';


class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings, [void Function(Locale)? setLocale]) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case IntroScreen.routeName:
        return MaterialPageRoute(builder: (_) => IntroScreen(setLocale: setLocale));
      case RoleSelectionScreen.routeName:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      case LoginScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case ProductsPage.routeName:
        return MaterialPageRoute(builder: (_) => const ProductsPage());

      case BuyerOrdersScreen.routeName:
        // buyerType passed via route arguments when available.
        final buyerType = settings.arguments is String
            ? settings.arguments as String
            : null;
        return MaterialPageRoute(
            builder: (_) => BuyerOrdersScreen(buyerType: buyerType));

      case AdminUsersScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AdminUsersScreen());

      case AdminStatisticsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AdminStatisticsScreen());

      case AdminOrdersScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AdminOrdersScreen());

      case AdminFinanceScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AdminFinanceScreen());

      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text(
            'Navigation error: Invalid or missing arguments.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      ),
    );
  }
}