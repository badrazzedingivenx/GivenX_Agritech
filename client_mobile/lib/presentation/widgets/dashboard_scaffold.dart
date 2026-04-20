import 'package:flutter/material.dart';

/// A nav item descriptor for the bottom navigation bar.
class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

class DashboardScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? floatingActionButton;

  /// Custom nav items. Defaults to Home / Products / Orders / Profile.
  final List<NavItem>? navItems;

  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _bgColor = Color(0xFFF4F9F3);
  static const Color _navUnselected = Color(0xFF8D9991);

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
  });

  List<NavItem> get _items => navItems ?? _defaultNavItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: appBar ?? _buildAppBar(context),
      body: body,
      floatingActionButton: floatingActionButton,
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
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined,
              color: _primaryGreen, size: 26),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
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
          final isSelected = i == currentIndex;
          final item = items[i];
          return GestureDetector(
            onTap: () => onTabSelected?.call(i),
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