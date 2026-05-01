import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:provider/provider.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';
import '../../../viewmodels/products_viewmodel.dart';

class ProductsPage extends StatelessWidget {
  static const routeName = '/products';
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductsViewModel>(
      create: (_) => ProductsViewModel()..loadProducts(),
      child: const _ProductsPageContent(),
    );
  }
}

class _ProductsPageContent extends StatefulWidget {
  const _ProductsPageContent();

  @override
  State<_ProductsPageContent> createState() => _ProductsPageContentState();
}

class _ProductsPageContentState extends State<_ProductsPageContent> {

  void _showLowStockAlert(List<Product> lowStockProducts) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Produits en rupture de stock", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 15),
              lowStockProducts.isEmpty 
                ? const Text("Kolchi mzian! Stock kafi.")
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: lowStockProducts.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const Icon(Icons.warning, color: Colors.orange),
                        title: Text(lowStockProducts[i].name),
                        trailing: Text("${lowStockProducts[i].quantity.toInt()} ${lowStockProducts[i].unit}",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    }
  final List<String> categories = ["All", "Vegetables", "Fruits", "Grains"];
  final List<String> units = ["Kg", "Ton", "Gram", "Piece"];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductsViewModel>();
    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
      );
    }
    if (vm.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: ${vm.error}'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => vm.loadProducts(), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.3, // Contrôle la transparence du fond
            child: Image.asset(
              'assets/images/app2.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Inventory', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      vm.lowStockCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                      color: vm.lowStockCount > 0 ? Colors.orange[700] : Colors.black87,
                    ),
                    onPressed: () => _showLowStockAlert(vm.products.where((p) => p.quantity < 5).toList()),
                  ),
                  if (vm.lowStockCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${vm.lowStockCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Colors.black87),
                onSelected: (value) => vm.setSortBy(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: "Name", child: Text("Sort by Name")),
                  const PopupMenuItem(value: "Price", child: Text("Sort by Price")),
                  const PopupMenuItem(value: "Stock", child: Text("Sort by Stock")),
                ],
              ),
            ],
// ...existing code...
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/app2.png'),
                  radius: 22,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 8),
                child: TextField(
                  onChanged: (val) => vm.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: "Rechercher...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: vm.selectedCategory == cat,
                      onSelected: (val) => vm.setCategory(cat),
                      selectedColor: const Color(0xFF1B5E20),
                      labelStyle: TextStyle(color: vm.selectedCategory == cat ? Colors.white : Colors.black87),
                    ),
                  )).toList(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vm.filteredProducts.length,
                  itemBuilder: (context, index) => _buildLargeProductCard(vm.filteredProducts[index]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showCalculator, 
            backgroundColor: Colors.orange[700], 
            child: const Icon(Icons.calculate, color: Colors.white)
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(Product product) {
    final img = product.image;
    if (img != null && img.startsWith('data:image')) {
      // Base64 data URI
      final base64Str = img.split(',').last;
      return Image.memory(
        base64Decode(base64Str),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    } else if (img != null && img.startsWith('assets/')) {
      // Local asset
      return Image.asset(
        img,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
    );
  }

  Widget _buildLargeProductCard(Product product) {
    bool isOutOfStock = product.quantity <= 0 || !product.isAvailable;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Opacity(
              opacity: isOutOfStock ? 0.3 : 1.0,
              child: _buildProductImage(product),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Text(
                      "${product.price.toStringAsFixed(2)} MAD/${product.unit}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isOutOfStock ? "OUT OF STOCK" : "In Stock: ${product.quantity.toInt()} ${product.unit}",
                  style: TextStyle(
                    color: isOutOfStock ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.description,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showEditSheet(product),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("EDIT"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDelete(product),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text("DELETE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ProductsViewModel>().deleteProduct(product.id!);
              if (!mounted) return;
              context.read<ProductsViewModel>().loadProducts();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toStringAsFixed(2));
    final stockController = TextEditingController(text: product.quantity.toInt().toString());
    final descController = TextEditingController(text: product.description);
    String tempUnit = product.unit;
    bool tempAvailable = product.isAvailable;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Edit Product", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: tempUnit,
                      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => setSheetState(() => tempUnit = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(controller: stockController, decoration: const InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Available in Stock"),
                  value: tempAvailable,
                  activeColor: Colors.green,
                  onChanged: (val) => setSheetState(() => tempAvailable = val),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String name = nameController.text.trim();
                      String price = priceController.text.trim();
                      String desc = descController.text.trim();
                      if (name.isEmpty || desc.isEmpty || double.tryParse(price) == null || double.parse(price) <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid name, description, and a positive price.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      try {
                        await ApiService.updateProduct(product.id!, {
                          'name': name,
                          'price': double.parse(price),
                          'quantity': double.tryParse(stockController.text) ?? 0,
                          'unit': tempUnit,
                          'isAvailable': tempAvailable,
                          'description': desc,
                        });
                        if (!mounted) return;
                        Navigator.pop(context);
                        context.read<ProductsViewModel>().loadProducts();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update failed: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Calculator UI (Simplified for space) ---
  void _showCalculator() {
    String exp = ""; String res = "0";
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(color: Color(0xFF1B5E20), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.horizontal_rule, color: Colors.white54, size: 40),
              Container(alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(exp, style: const TextStyle(fontSize: 22, color: Colors.white70)),
                  Text(res, style: const TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
              Expanded(
                child: GridView.count(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10,
                  children: ["C", "÷", "×", "DEL", "7", "8", "9", "-", "4", "5", "6", "+", "1", "2", "3", "=", "0", "."].map((btn) => ElevatedButton(
                    onPressed: () => setModalState(() {
                      if (btn == "C") { exp = ""; res = "0"; }
                      else if (btn == "=") {
                        try {
                          Parser p = Parser(); Expression mathExp = p.parse(exp.replaceAll('×', '*').replaceAll('÷', '/'));
                          double eval = mathExp.evaluate(EvaluationType.REAL, ContextModel());
                          res = eval == eval.toInt() ? eval.toInt().toString() : eval.toStringAsFixed(2);
                        } catch (e) { res = "Error"; }
                      } else { exp += btn; }
                    }),
                    child: Text(btn),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}