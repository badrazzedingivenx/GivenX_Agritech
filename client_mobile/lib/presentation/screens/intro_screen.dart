import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'login_screen.dart';

class IntroScreen extends StatefulWidget {
  static const routeName = '/intro';
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/app2.png',
      'title': 'Farmer',
      'desc': 'Publish your harvests, receive orders, and request financing.'
    },
    {
      'image': 'assets/images/app3.png',
      'title': 'Factory / Exporter',
      'desc': 'Publish orders, track shipments, and manage your supply chain.'
    },
    {
      'image': 'assets/images/app4.png',
      'title': 'Transporter',
      'desc': 'View assigned deliveries, accept new missions, and optimize your routes.'
    },
    // Removed financer/financeur page
  ];

  @override
  Widget build(BuildContext context) {
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
          // Gradient overlay (same as before)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xCCF8F5F2), // 80% opacity
                  Color(0xCCF3EBDD), // 80% opacity
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
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
                                  padding: const EdgeInsets.only(right: 24.0, top: 16),
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
                                    count: _pages.length,
                                    effect: const WormEffect(
                                      dotColor: Color(0xFFB2DFDB),
                                      activeDotColor: Color(0xFF2E7D32),
                                      dotHeight: 10,
                                      dotWidth: 10,
                                    ),
                                  ),
                                          if (index == _pages.length - 1)
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
                                              child: const Text(
                                                'Get Started',
                                                style: TextStyle(
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
                                              child: const Text(
                                                'Next',
                                                style: TextStyle(
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
            ),
          ),
        ],
      ),
    );
  }
}
