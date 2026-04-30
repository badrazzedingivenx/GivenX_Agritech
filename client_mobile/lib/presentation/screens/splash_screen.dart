import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../models/user.dart';
import 'dashboard/farmer_dashboard.dart';
import 'dashboard/usine_dashboard.dart';
import 'dashboard/transporteur_dashboard.dart';
import 'dashboard/banque_dashboard.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 4), () {
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    final user = await SessionService.getUser();
    if (!mounted) return;

    if (user != null) {
      _navigateToDashboard(user);
    } else {
      Navigator.of(context).pushReplacementNamed('/intro');
    }
  }

  void _navigateToDashboard(User user) {
    Widget dashboard;
    switch (user.role) {
      case UserRole.farmer:
        dashboard = FarmerDashboard(
          fullName: user.fullName,
          email: user.email,
          phone: user.phone,
          city: user.city,
          farmingType: user.farmingType ?? '',
          mainProducts: user.mainProducts ?? '',
        );
      case UserRole.buyer:
        dashboard = UsineDashboard(
          fullName: user.fullName,
          email: user.email,
          phone: user.phone,
          city: user.city,
          companyName: user.companyName ?? '',
          productTypes: user.productTypes ?? '',
          buyerType: user.buyerType?.toJson() ?? 'restaurant',
          userId: user.id,
        );
      case UserRole.transporter:
        dashboard = TransporteurDashboard(
          fullName: user.fullName,
          email: user.email,
          phone: user.phone,
          city: user.city,
          vehicleType: user.vehicleType ?? '',
          capacity: user.capacity ?? '',
        );
      case UserRole.bank:
        dashboard = BanqueDashboard(
          bankName: user.bankName ?? '',
          officialId: user.officialId ?? '',
          email: user.email,
          phone: user.phone,
          logoPath: user.logoPath ?? '',
        );
      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed('/intro');
        return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/app1.png',
            fit: BoxFit.cover,
          ),
          // Move logo higher by using a Column
          Column(
            children: [
              const SizedBox(height: 20), // Move logo even higher
              FadeTransition(
                opacity: _animation,
                child: ScaleTransition(
                  scale: _animation,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 320,
                    height: 320,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
