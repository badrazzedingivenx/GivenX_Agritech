import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  String selectedFilter = "ALL";

  final List<Map<String, dynamic>> orders = [
    {
      "title": "Organic Grocers Inc.",
      "product": "14kg Tomatoes",
      "id": "#ORD-7721",
      "price": "420.00 MAD",
      "status": "IN TRANSIT",
      "color": Colors.orange,
    },
    {
      "title": "Fresh Daily Market",
      "product": "50kg Wheat",
      "id": "#ORD-7719",
      "price": "1,280.00 MAD",
      "status": "PROCESSING",
      "color": Colors.blue,
    },
    {
      "title": "The Green Table",
      "product": "8kg Microgreens",
      "id": "#ORD-7715",
      "price": "215.00 MAD",
      "status": "COMPLETED",
      "color": Colors.green,
    },
  ];

  List<Map<String, dynamic>> get filteredOrders {
    if (selectedFilter == "ALL") return orders;
    return orders
        .where((o) => o["status"] == selectedFilter)
        .toList();
  }

  void deleteOrder(int index) {
    setState(() {
      filteredOrders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Orders"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Column(
        children: [

          /// ================= FILTER TABS =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _filterTab("ALL"),
                _filterTab("PROCESSING"),
                _filterTab("COMPLETED"),
              ],
            ),
          ),

          const SizedBox(height: 5),

          /// ================= LIST =================
          Expanded(
            child: ListView.builder(
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: _orderCard(order, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= FILTER TAB =================
  Widget _filterTab(String text) {
    final isActive = selectedFilter == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = text;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// ================= ORDER CARD (SWIPE + ANIMATION) =================
  Widget _orderCard(Map<String, dynamic> order, int index) {
    return Dismissible(
      key: UniqueKey(),

      background: _swipeBackground(Icons.delete, Colors.red),
      secondaryBackground:
          _swipeBackground(Icons.check, Colors.green),

      /// Swipe actions
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // mark delivered
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Marked as delivered")),
          );
        } else {
          deleteOrder(index);
        }
      },

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TOP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        (order["color"] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order["status"],
                    style: TextStyle(
                      fontSize: 10,
                      color: order["color"],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "${order["product"]} • ${order["id"]}",
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.shopping_bag, color: Colors.green),
                Text(
                  order["price"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SWIPE UI =================
  Widget _swipeBackground(IconData icon, Color color) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: color,
      child: Icon(icon, color: Colors.white),
    );
  }
}