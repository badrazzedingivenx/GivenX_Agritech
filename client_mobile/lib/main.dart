import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'presentation/navigation/app_router.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const AgriFlowApp());
}

class AgriFlowApp extends StatefulWidget {
  const AgriFlowApp({super.key});

  @override
  State<AgriFlowApp> createState() => _AgriFlowAppState();
}

class _AgriFlowAppState extends State<AgriFlowApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

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
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      initialRoute: '/splash',
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, setLocale),
      debugShowCheckedModeBanner: false,
    );
  }
}
