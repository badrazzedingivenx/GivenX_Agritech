import 'package:flutter/material.dart';
import 'presentation/navigation/app_router.dart';



void main() {
  runApp(const AgriFlowApp());
}

class AgriFlowApp extends StatelessWidget {
  const AgriFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF1B5E20),
          onPrimary: Colors.white,
          secondary: Color(0xFFE8F5E9),
          onSecondary: Color(0xFF1B5E20),
          background: Color(0xFFF8FAF8),
          onBackground: Color(0xFF1B5E20),
          surface: Colors.white,
          onSurface: Colors.black87,
          error: Color(0xFFB00020),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAF8),
        primaryColor: const Color(0xFF1B5E20),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
          titleTextStyle: TextStyle(color: Color(0xFF1B5E20), fontSize: 20, fontWeight: FontWeight.bold),
          toolbarTextStyle: TextStyle(color: Colors.black87, fontSize: 16),
          surfaceTintColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1B5E20),
            side: const BorderSide(color: Color(0xFF1B5E20)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B5E20)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.symmetric(vertical: 10),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE8F5E9),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5)),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 13, color: Colors.black54),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
        ),
      ),
      initialRoute: '/splash',
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
