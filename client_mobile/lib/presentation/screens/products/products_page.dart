import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// --- Model ---
class Product {
  String id, name, category, price, unit, image, description;
  int stockQuantity;
  bool isAvailable;
  File? localImage;

  Product({
    required this.id, required this.name, required this.category,
    required this.price, required this.unit, required this.image,
    this.stockQuantity = 10, this.isAvailable = true, this.localImage,
    this.description = "Fresh agricultural product, harvested with care.",
  });
}

class ProductsPage extends StatefulWidget {
  static const routeName = '/products';
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
    void _showLowStockAlert() {
      final lowStockProducts = myProducts.where((p) => p.stockQuantity < 5).toList();
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
                        trailing: Text("${lowStockProducts[i].stockQuantity} ${lowStockProducts[i].unit}",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    }
  String searchQuery = "";
  String selectedCategory = "All";
  String sortBy = "Name";

  final List<String> categories = ["All", "Vegetables", "Fruits", "Grains"];
  final List<String> units = ["Kg", "Ton", "Gram", "Piece"];

  List<Product> myProducts = [
    // Fruits
    Product(id: "1", name: "Red Apples", category: "Fruits", price: "22.00", unit: "Kg", image: "assets/images/appApple.png", stockQuantity: 12, isAvailable: true),
    Product(id: "2", name: "Bananas", category: "Fruits", price: "15.00", unit: "Kg", image: "assets/images/appbanans.png", stockQuantity: 20, isAvailable: true),
    Product(id: "3", name: "Oranges", category: "Fruits", price: "13.00", unit: "Kg", image: "assets/images/appOranges.png", stockQuantity: 0, isAvailable: false),
    Product(id: "4", name: "Strawberries", category: "Fruits", price: "35.00", unit: "Kg", image: "assets/images/appstrawberries.png", stockQuantity: 7, isAvailable: true),

    // Vegetables
    Product(id: "5", name: "Fresh Tomatoes", category: "Vegetables", price: "12.50", unit: "Kg", image: "assets/images/appTomat.jpg", stockQuantity: 50, isAvailable: true),
    Product(id: "6", name: "Potatoes", category: "Vegetables", price: "8.00", unit: "Kg", image: "assets/images/appPotatos.png", stockQuantity: 15, isAvailable: true),
    Product(id: "7", name: "Cabbage", category: "Vegetables", price: "10.00", unit: "Kg", image: "assets/images/appcabbage.png", stockQuantity: 9, isAvailable: true),
    Product(id: "8", name: "Carrots", category: "Vegetables", price: "9.00", unit: "Kg", image: "assets/images/appcarrot.png", stockQuantity: 0, isAvailable: false),
    Product(id: "9", name: "Onions", category: "Vegetables", price: "7.00", unit: "Kg", image: "assets/images/apponions.png", stockQuantity: 18, isAvailable: true),

    // Grains
    Product(id: "10", name: "Premium Durum Wheat", category: "Grains", price: "420", unit: "Ton", image: "assets/images/appweight.jpg", stockQuantity: 3, isAvailable: true),
    Product(id: "11", name: "Oats", category: "Grains", price: "350", unit: "Ton", image: "assets/images/appOats.png", stockQuantity: 2, isAvailable: true),
    Product(id: "12", name: "Sunflower Seeds", category: "Grains", price: "600", unit: "Ton", image: "assets/images/appSunflowers_Seeds.png", stockQuantity: 0, isAvailable: false),
  ];

  List<Product> get filteredProducts {
    List<Product> list = myProducts.where((product) {
      final matchesCategory = selectedCategory == 'All' || product.category == selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (sortBy == "Price") {
      list.sort((a, b) => double.parse(a.price).compareTo(double.parse(b.price)));
    } else if (sortBy == "Stock") {
      list.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  int get lowStockCount => myProducts.where((p) => p.stockQuantity < 5).length;

  Future<void> _updateProductImage(Product product, ImageSource source, StateSetter setSheetState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setSheetState(() => product.localImage = File(pickedFile.path));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      lowStockCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                      color: lowStockCount > 0 ? Colors.orange[700] : Colors.black87,
                    ),
                    onPressed: _showLowStockAlert, // Affiche la liste des produits en rupture
                  ),
                  if (lowStockCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$lowStockCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Colors.black87),
                onSelected: (value) => setState(() => sortBy = value),
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
                  onChanged: (val) => setState(() => searchQuery = val),
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
                      selected: selectedCategory == cat,
                      onSelected: (val) => setState(() => selectedCategory = cat),
                      selectedColor: const Color(0xFF1B5E20),
                      labelStyle: TextStyle(color: selectedCategory == cat ? Colors.white : Colors.black87),
                    ),
                  )).toList(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) => _buildLargeProductCard(filteredProducts[index]),
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

  Widget _buildLargeProductCard(Product product) {
    bool isOutOfStock = product.stockQuantity <= 0 || !product.isAvailable;
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
              child: product.localImage != null
                  ? Image.file(
                      product.localImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      product.image,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
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
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      "${product.price} ${product.unit}",
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
                  isOutOfStock ? "OUT OF STOCK" : "In Stock: ${product.stockQuantity} ${product.unit}",
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price);
    final stockController = TextEditingController(text: product.stockQuantity.toString());
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: () => _updateProductImage(product, ImageSource.camera, setSheetState), icon: const Icon(Icons.camera_alt, color: Colors.green)),
                    const Text("Change Image"),
                    IconButton(onPressed: () => _updateProductImage(product, ImageSource.gallery, setSheetState), icon: const Icon(Icons.image, color: Colors.green)),
                  ],
                ),
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
                    onPressed: () {
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
                      setState(() {
                        product.name = name;
                        product.price = price;
                        product.stockQuantity = int.tryParse(stockController.text) ?? 0;
                        product.unit = tempUnit;
                        product.isAvailable = tempAvailable;
                        product.description = desc;
                      });
                      Navigator.pop(context);
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