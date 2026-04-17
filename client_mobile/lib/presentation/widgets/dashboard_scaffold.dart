import 'package:flutter/material.dart';

/// Shared dashboard scaffold for all roles
class DashboardScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? floatingActionButton;

  const DashboardScaffold({
    super.key,
    required this.body,
    this.currentIndex = 0,
    this.onTabSelected,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: appBar ?? _defaultAppBar(context),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  PreferredSizeWidget _defaultAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Image.asset(
        'assets/images/logo.png',
        height: 90,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Color(0xFF2E7D32)),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, color: Color(0xFF2E7D32)),
          ),
        ),
      ],
    );
  }
}
