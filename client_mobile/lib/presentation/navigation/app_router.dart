import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/login_screen.dart';
import '../screens/products/Addproducts_page.dart';
import '../screens/products/products_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case IntroScreen.routeName:
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      case RoleSelectionScreen.routeName:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case LoginScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case ProductsPage.routeName:
        return MaterialPageRoute(builder: (_) => const ProductsPage());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
