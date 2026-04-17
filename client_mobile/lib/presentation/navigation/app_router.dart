import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/login_screen.dart';

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
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
