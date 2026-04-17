import 'package:flutter/material.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../l10n/app_localizations.dart';
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
  int _currentPage = 0;

  List<Map<String, String>> _localizedPages(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      {
        'image': 'assets/images/app2.png',
        'title': loc.introFarmerTitle,
        'desc': loc.introFarmerDesc,
      },
      {
        'image': 'assets/images/app3.png',
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
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final double maxImageHeight = constraints.maxHeight * 0.48;
                            final double imageCardRadius = 28;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Skip button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: Directionality.of(context) == TextDirection.rtl
                                          ? const EdgeInsets.only(left: 24.0, top: 16)
                                          : const EdgeInsets.only(right: 24.0, top: 16),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(22),
                                          onTap: () => Navigator.of(context).pushReplacementNamed(LoginScreen.routeName),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(22),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Text(
                                              'Skip',
                                              style: TextStyle(
                                                color: Color(0xFF2E7D32),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  flex: 7,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Image card with gradient overlay and shadow
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 18),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(imageCardRadius),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.10),
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
                                                  width: MediaQuery.of(context).size.width * 0.8,
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
                                        const SizedBox(height: 36),
                                        // Title
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 32),
                                          child: Text(
                                            page['title']!,
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B5E20),
                                              letterSpacing: 0.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        // Description
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 32),
                                          child: Text(
                                            page['desc']!,
                                            style: const TextStyle(
                                              fontSize: 16,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
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
                                              borderRadius: BorderRadius.circular(28),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                                            elevation: 10,
                                            shadowColor: const Color(0xFF2E7D32).withOpacity(0.22),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)!.getStarted,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
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
                                              borderRadius: BorderRadius.circular(28),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                                            elevation: 10,
                                            shadowColor: const Color(0xFF2E7D32).withOpacity(0.22),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)!.next,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Language picker icon (top left for LTR, top right for RTL)
          Positioned(
            top: 16,
            left: Directionality.of(context) == TextDirection.rtl ? null : 16,
            right: Directionality.of(context) == TextDirection.rtl ? 16 : null,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.translate, color: Color(0xFF2E7D32), size: 32),
                onPressed: () {
                  debugPrint('Translate icon tapped');
                  _showLanguagePicker(context);
                },
                tooltip: 'Choose Language',
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language, color: Color(0xFF2E7D32), size: 26),
                      const SizedBox(width: 10),
                      Text(
                        loc?.chooseLanguage ?? 'Choose Language',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(thickness: 1.2, color: Color(0xFFB2DFDB)),
                _buildLangTile(
                  context,
                  langCode: 'en',
                  title: 'English',
                  icon: Icons.language,
                  iconColor: Color(0xFF1976D2),
                  selected: currentLocale == 'en',
                ),
                _buildLangTile(
                  context,
                  langCode: 'fr',
                  title: 'Français',
                  icon: Icons.language,
                  iconColor: Color(0xFFD32F2F),
                  selected: currentLocale == 'fr',
                ),
                _buildLangTile(
                  context,
                  langCode: 'ar',
                  title: 'العربية',
                  icon: Icons.language,
                  iconColor: Color(0xFF388E3C),
                  selected: currentLocale == 'ar',
                ),
                _buildLangTile(
                  context,
                  langCode: 'es',
                  title: 'Español',
                  icon: Icons.language,
                  iconColor: Color(0xFFF57C00),
                  selected: currentLocale == 'es',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

  }

  Widget _buildLangTile(BuildContext context, {
    required String langCode,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2),
      child: Material(
        color: selected ? const Color(0xFFE8F5E9) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            debugPrint('Switching to $title');
            widget.setLocale?.call(Locale(langCode));
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 26),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: selected ? Color(0xFF2E7D32) : Color(0xFF222222),
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
