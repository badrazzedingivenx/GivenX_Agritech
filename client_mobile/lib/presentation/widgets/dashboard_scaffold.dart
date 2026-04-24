import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/notifications/notifications_screen.dart';
import '../../services/notification_badge_service.dart';

/// A nav item descriptor for the bottom navigation bar.
class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

class DashboardScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? floatingActionButton;
  final List<NavItem>? navItems;
  final Map<int, int>? navBadgeCounts;

  /// For notification bell — pass role and userId from each dashboard
  final String? userRole;
  final int? userId;

  static const List<NavItem> _defaultNavItems = [
    NavItem(icon: Icons.home_outlined, label: 'Home'),
    NavItem(icon: Icons.shopping_bag_outlined, label: 'Products'),
    NavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
    NavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  const DashboardScaffold({
    super.key,
    required this.body,
    this.currentIndex = 0,
    this.onTabSelected,
    this.appBar,
    this.floatingActionButton,
    this.navItems,
    this.navBadgeCounts,
    this.userRole,
    this.userId,
  });

  @override
  State<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> {
  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _bgColor = Color(0xFFF4F9F3);
  static const Color _navUnselected = Color(0xFF8D9991);

  int _bellBadge = 0;
  Timer? _pollTimer;

  List<NavItem> get _items => widget.navItems ?? DashboardScaffold._defaultNavItems;

  @override
  void initState() {
    super.initState();
    _refreshBadge();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshBadge());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshBadge() async {
    if (widget.userRole == null || widget.userId == null) return;
    final count = await NotificationBadgeService.fetchBadgeCount(
      widget.userRole!,
      widget.userId!,
    );
    if (mounted) setState(() => _bellBadge = count);
  }

  Future<void> _openNotifications() async {
    if (widget.userRole == null || widget.userId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          role: widget.userRole!,
          userId: widget.userId!,
        ),
      ),
    );
    _refreshBadge();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: widget.appBar ?? _buildAppBar(context),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/logo.png',
          height: 160,
          width: 160,
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        // Badge is inside icon: so the IconButton size/position is unchanged
        IconButton(
          onPressed: _openNotifications,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined,
                  color: _primaryGreen, size: 26),
              if (_bellBadge > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _bgColor, width: 1.5),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _bellBadge > 99 ? '99+' : '$_bellBadge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = _items;
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 24, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isSelected = i == widget.currentIndex;
          final item = items[i];
          return GestureDetector(
            onTap: () => widget.onTabSelected?.call(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon,
                      color: isSelected ? Colors.white : _navUnselected,
                      size: 22),
                  if ((widget.navBadgeCounts?[i] ?? 0) > 0)
                    Transform.translate(
                      offset: const Offset(-6, -8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          (widget.navBadgeCounts?[i] ?? 0) > 99 ? '99+' : '${widget.navBadgeCounts?[i]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(item.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}