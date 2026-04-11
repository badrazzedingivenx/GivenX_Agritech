import 'dart:async';
import 'package:flutter/material.dart';

class UsineDashboard extends StatelessWidget {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? city;
  final String? companyName;
  final String? productTypes;

  const UsineDashboard({
    super.key,
    this.fullName,
    this.email,
    this.phone,
    this.city,
    this.companyName,
    this.productTypes,
  });

  // Colors based on the UI design
  final Color bgColor = const Color(0xFFF4F9F3);
  final Color primaryGreen = const Color(0xFF23763D);
  final Color textColor = const Color(0xFF1A1D1A);
  final Color textLightColor = const Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    String displayName = fullName?.isNotEmpty == true ? fullName! : 'Alexander';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("EXPORTER DASHBOARD",
                style: TextStyle(
                    color: primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text("Hello, $displayName",
                style: TextStyle(
                    fontSize: 28,
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text("Here is the status of your global shipments today.",
                style: TextStyle(color: textLightColor, fontSize: 13)),
            
            const SizedBox(height: 24),

            // 1. Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                      "Manage\nProducts", Icons.inventory_2_outlined, false),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionButton("Add\nShipment", Icons.add, true),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. Statistics Cards
            _buildStatCard(
                icon: Icons.local_shipping,
                iconBgColor: const Color(0xFFDDF1E3),
                iconColor: primaryGreen,
                value: "15",
                title: "Total Shipments",
                badge: "+2 new"),
            const SizedBox(height: 15),
            _buildStatCard(
                icon: Icons.public,
                iconBgColor: const Color(0xFFFCEAE8),
                iconColor: const Color(0xFFB52B35),
                value: "4",
                title: "Countries Active"),

            const SizedBox(height: 20),

            // 3. Live Network (Map Card)
            _buildMapCard(),

            const SizedBox(height: 28),

            // 4. Active Batches Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text("Active Batches",
                    style: TextStyle(
                        fontSize: 18,
                        color: textColor,
                        fontWeight: FontWeight.w800)),
                Text("View All",
                    style: TextStyle(
                        color: primaryGreen, 
                        fontWeight: FontWeight.w700, 
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Batches List
            _buildBatchItem(
              icon: Icons.inventory_2,
              title: "Batch #EXP-915",
              subtitle: "Destination: Rotterdam, NL",
              statusText: "DELIVERED",
              statusBgColor: primaryGreen,
              statusTextColor: Colors.white,
            ),
            _buildBatchItem(
              icon: Icons.sailing,
              title: "Batch #EXP-884",
              subtitle: "Destination: Singapore, SG",
              statusText: "SHIPPED",
              statusBgColor: const Color(0xFFC7E5C9),
              statusTextColor: primaryGreen,
            ),
            _buildBatchItem(
              icon: Icons.pending_actions,
              title: "Batch #EXP-902",
              subtitle: "Status: Processing Manifest",
              statusText: "PENDING",
              statusBgColor: const Color(0xFFE0E5E0),
              statusTextColor: const Color(0xFF555555),
            ),

            const SizedBox(height: 15),

            // 6. Supply Chain Insight Card
            _buildInsightCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Widgets ---

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.eco_outlined, color: primaryGreen, size: 20),
          ),
          const SizedBox(width: 8),
          Text("AgriFlow",
              style: TextStyle(
                  color: primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_outlined, color: primaryGreen, size: 26),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isPrimary ? primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPrimary
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : textColor, size: 20),
          const SizedBox(width: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isPrimary ? Colors.white : textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon,
      required Color iconBgColor,
      required Color iconColor,
      required String value,
      required String title,
      String? badge}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(badge,
                      style: TextStyle(
                          color: primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                  fontSize: 32, 
                  color: textColor,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title, 
              style: TextStyle(color: textLightColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return const LiveNetworkCard();
  }

  Widget _buildBatchItem(
      {required IconData icon,
      required String title,
      required String subtitle,
      required String statusText,
      required Color statusBgColor,
      required Color statusTextColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF4F6F4),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: const Color(0xFF5A5E5A), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800, 
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: textLightColor, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(12)),
            child: Text(statusText,
                style: TextStyle(
                    color: statusTextColor, 
                    fontSize: 10, 
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.bar_chart, 
                size: 150, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Supply Chain Insight",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    children: [
                      TextSpan(text: "Your export volume to "),
                      TextSpan(
                          text: "Netherlands",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              " has increased by 22% this quarter. Consider optimizing freight routes for better margins."),
                    ]
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: const Text("View Report",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 25, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Selected Home
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen, 
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.home, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text("Home", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          // Unselected Shipments
          _buildNavItem(Icons.eco, "Shipments"),
          // Unselected Products
          _buildNavItem(Icons.shopping_cart_outlined, "Products"),
          // Unselected Profile
          _buildNavItem(Icons.person_outline, "Profile"),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF8D9991), size: 24),
        const SizedBox(height: 4),
        Text(label, 
            style: const TextStyle(
                color: Color(0xFF8D9991), 
                fontSize: 11, 
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ============== ANIMATED LIVE NETWORK CARD ==============

class LiveNetworkCard extends StatefulWidget {
  const LiveNetworkCard({super.key});

  @override
  State<LiveNetworkCard> createState() => _LiveNetworkCardState();
}

class _LiveNetworkCardState extends State<LiveNetworkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _activeNodes = 12450;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation =
        Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Simulate real-time data changes
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Random fluctuation
          int change = (DateTime.now().millisecond % 15) - 5;
          _activeNodes += change;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170, // Slightly taller for more effect
      width: double.infinity,
      decoration: BoxDecoration(
          color: const Color(0xFF0F3628), // deep dark green
          borderRadius: BorderRadius.circular(28),
          image: const DecorationImage(
            image: NetworkImage(
                'https://www.transparenttextures.com/patterns/world-map.png'),
            fit: BoxFit.cover,
            opacity: 0.3, // Slightly more visible
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F3628).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ]),
      child: Stack(
        children: [
          // Simulated pulsing shipment locations on the map
          Positioned(top: 40, left: 60, child: _buildPulsingDot()),
          Positioned(top: 80, left: 140, child: _buildPulsingDot(delay: 500)),
          Positioned(top: 60, right: 80, child: _buildPulsingDot(delay: 1000)),
          Positioned(bottom: 60, right: 120, child: _buildPulsingDot()),
          Positioned(top: 90, right: 40, child: _buildPulsingDot(delay: 1500)),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Live Network",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text("Tracking global logistics...",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Live numbers changing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            FadeTransition(
                              opacity: _pulseAnimation,
                              child: const Icon(Icons.circle,
                                  color: Color(0xFFFF5252), size: 10),
                            ),
                            const SizedBox(width: 5),
                            const Text("LIVE",
                                style: TextStyle(
                                    color: Color(0xFFFF5252),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, -0.3),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            "$_activeNodes",
                            key: ValueKey<int>(_activeNodes),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A tiny glowing dot to put on the map
  Widget _buildPulsingDot({int delay = 0}) {
    // using fade animation for all, if we want delay we could use multiple controllers,
    // but relying on one controller is fine for a unified pulse effect
    return FadeTransition(
      opacity: _pulseAnimation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
            color: const Color(0xFF43EA7A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF43EA7A).withValues(alpha: 0.8),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ]),
      ),
    );
  }
}
