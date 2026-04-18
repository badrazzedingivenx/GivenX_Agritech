import 'package:flutter/material.dart';

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
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          onTabSelected?.call(index);
        },

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
      automaticallyImplyLeading: false,
      title: const Text("Farmer App"),

      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),

        GestureDetector(
          onTap: () {
            onTabSelected?.call(3);
          },
          child: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(child: Icon(Icons.person)),
          ),
        ),
      ],
    );
  }
}