import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/role_selection_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case IntroScreen.routeName:
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      case RoleSelectionScreen.routeName:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
