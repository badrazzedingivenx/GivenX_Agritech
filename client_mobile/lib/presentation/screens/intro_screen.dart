import 'package:flutter/material.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../l10n/app_localizations.dart';
import '../../services/locale_controller.dart';
import 'login_screen.dart';


typedef SetLocaleCallback = void Function(Locale locale);

class IntroScreen extends StatefulWidget {
  static const routeName = '/intro';
  final SetLocaleCallback? setLocale;
  const IntroScreen({super.key, this.setLocale});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();

  List<Map<String, String>> _localizedPages(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      {
        'image': 'assets/images/app2.png',
        'title': loc.introFarmerTitle,
        'desc': loc.introFarmerDesc,
      },
      {
        'image': 'assets/images/app30.png',
        'title': loc.introFactoryTitle,
        'desc': loc.introFactoryDesc,
      },
      {
        'image': 'assets/images/app4.png',
        'title': loc.introTransporterTitle,
        'desc': loc.introTransporterDesc,
      },
      {
        'image': 'assets/images/app5.png',
        'title': loc.introBankTitle,
        'desc': loc.introBankDesc,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _localizedPages(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background image (same as role selection)
          Positioned.fill(
            child: Image.asset(
              'assets/images/app1.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xCCF8F5F2),
                  Color(0xCCF3EBDD),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Main content
                  Center(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length,
                      onPageChanged: (_) {},
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final double maxImageHeight = constraints.maxHeight * 0.38;
                            const double imageCardRadius = 24;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Space reserved for the top bar overlay
                                const SizedBox(height: 56),
                                Expanded(
                                  flex: 7,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Image card with gradient overlay and shadow
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 24),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(imageCardRadius),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.10),
                                                blurRadius: 32,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(imageCardRadius),
                                            child: Stack(
                                              children: [
                                                Image.asset(
                                                  page['image']!,
                                                  height: maxImageHeight,
                                                  width: MediaQuery.of(context).size.width * 0.75,
                                                  fit: BoxFit.cover,
                                                ),
                                                // Soft white gradient overlay from top
                                                Positioned(
                                                  top: 0,
                                                  left: 0,
                                                  right: 0,
                                                  height: 80,
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          Colors.white54,
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // Title
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 28),
                                          child: Text(
                                            page['title']!,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B5E20),
                                              letterSpacing: 0.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Description
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 28),
                                          child: Text(
                                            page['desc']!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF6D6D6D),
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Indicators and button
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      SmoothPageIndicator(
                                        controller: _controller,
                                        count: pages.length,
                                        effect: const WormEffect(
                                          dotColor: Color(0xFFB2DFDB),
                                          activeDotColor: Color(0xFF2E7D32),
                                          dotHeight: 10,
                                          dotWidth: 10,
                                        ),
                                      ),
                                      if (index == pages.length - 1)
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2E7D32),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                            elevation: 10,
                                            shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.22),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)!.getStarted,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: () {
                                            _controller.nextPage(
                                              duration: const Duration(milliseconds: 400),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2E7D32),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                                            elevation: 10,
                                            shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.22),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)!.next,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Top bar: language button (left) + Skip button (right)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Language / translate button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _showLanguagePicker(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.translate, color: Color(0xFF2E7D32), size: 18),
                            ),
                          ),
                        ),
                        // Skip button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => Navigator.of(context).pushReplacementNamed(LoginScreen.routeName),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.skip,
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        final loc = AppLocalizations.of(context);
        final languages = [
          {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
          {'code': 'fr', 'name': 'French', 'native': 'Français', 'flag': '🇫🇷'},
          {'code': 'ar', 'name': 'Arabic', 'native': 'العربية', 'flag': '🇸🇦'},
          {'code': 'es', 'name': 'Spanish', 'native': 'Español', 'flag': '🇪🇸'},
        ];
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCFBF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D6CE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.translate_rounded,
                            color: Color(0xFF2E7D32), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc?.chooseLanguage ?? 'Choose Language',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select your preferred language',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Language list
                  ...languages.map((lang) => _buildLangTile(
                        context,
                        langCode: lang['code']!,
                        title: lang['native']!,
                        subtitle: lang['name']!,
                        flag: lang['flag']!,
                        selected: currentLocale == lang['code'],
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangTile(BuildContext context, {
    required String langCode,
    required String title,
    required String subtitle,
    required String flag,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            LocaleController.setLocale(langCode, title);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE9E6DF),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                // Flag badge
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(flag, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: selected
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? const Color(0xFF2E7D32) : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFCFCBC2),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 15)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
