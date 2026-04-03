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
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Sans-serif',
        scaffoldBackgroundColor: const Color(0xFFF6F7F2),
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      initialRoute: '/splash',
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
