import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AddProductPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductAdded;
  const AddProductPage({super.key, required this.onProductAdded});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> with SingleTickerProviderStateMixin {

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final bulkQtyController = TextEditingController();
  final stockController = TextEditingController();
  final descController = TextEditingController();
  final costController = TextEditingController();
  final TextEditingController otherCategoryController = TextEditingController();

  bool isListening = false;
  bool _speechEnabled = false;
  final SpeechToText _speech = SpeechToText();

  String selectedUnit = "Kg";
  final List<String> units = ["Kg", "Bag (50kg)", "Bag (25kg)", "Ton"];
  String selectedCategory = 'Vegetable';
  final List<String> categories = ['Vegetable', 'Fruit', 'Grains', 'Others'];

  late AnimationController _animationController;
  final List<Uint8List> _imageBytesList = [];
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initSpeech();
    _speech.stop(); // ✅ FIX

    bulkQtyController.addListener(_updateStock);
  }

  void _initSpeech() async {
    bool available = await _speech.initialize();
    setState(() => _speechEnabled = available);
  }

  // ---------------- SPEECH ----------------
  void _startListening() async {
    if (!_speechEnabled) return;

    setState(() => isListening = true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          nameController.text = result.recognizedWords;
          if (result.finalResult) {
            isListening = false;
          }
        });
      },
      listenMode: ListenMode.dictation,
      partialResults: true,
    );
  }

  // ---------------- STOCK ----------------
  void _updateStock() {
    double qty = double.tryParse(bulkQtyController.text) ?? 0;
    double factor = 1.0;

    if (selectedUnit == "Bag (50kg)") factor = 50;
    else if (selectedUnit == "Bag (25kg)") factor = 25;
    else if (selectedUnit == "Ton") factor = 1000;

    stockController.text = (qty * factor).toStringAsFixed(2);
    setState(() {});
  }

  // ---------------- IMAGE PICKER ----------------
  Future<void> _pickImages(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        if (_imageBytesList.length < 3) {
          _imageBytesList.add(bytes);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Maximum 3 images allowed")),
          );
        }
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              _pickImages(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Library'),
            onTap: () {
              Navigator.pop(context);
              _pickImages(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  // ---------------- AI ----------------
  void _showAISheet() {
    double totalValue =
        (double.tryParse(stockController.text) ?? 0) *
        (double.tryParse(priceController.text) ?? 0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue),
                SizedBox(width: 10),
                Text("AI Analysis",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              ],
            ),
            const SizedBox(height: 15),
            Text("• Total Revenue: ${totalValue.toStringAsFixed(2)} DH"),
            const SizedBox(height: 10),
            const Text("• Market Tip: Selling in 'Bag' usually attracts wholesale buyers."),
          ],
        ),
      ),
    );
  }

  // ---------------- SUBMIT ----------------
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;

          final productData = {
            'name': nameController.text.trim(),
            'price': priceController.text.trim(),
            'quantity': bulkQtyController.text.trim(),
            'unit': selectedUnit,
            'stock': stockController.text.trim(),
            'description': descController.text.trim(),
            'images': _imageBytesList,
            'category': selectedCategory == 'Others'
                ? otherCategoryController.text.trim()
                : selectedCategory,
          };

          widget.onProductAdded(productData);

          // ✅ FIX snackbar before pop
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        },
        child: const Text(
          "CONFIRM & SAVE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFF1B5E20), size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: Image.asset(
              'assets/images/app2.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Add Product",
                style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF1B5E20)),
                onPressed: () {
                  // Action supprimée : ancienne navigation vers ProfileFarmerPage
                },
              ),
            ],
            elevation: 0,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔥 PHOTOS
                      Center(
                        child: Column(
                          children: [
                            _buildLabel("Product Photos (Max 3)"),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 180,
                              child: _buildPhotoSection(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 🔥 NAME + MIC
                      _buildLabel("Product Name *"),
                      TextFormField(
                        controller: nameController,
                        decoration: _inputDecoration(
                          "Ex: Premium potatoes",
                          Icons.inventory_2_outlined,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              isListening ? Icons.mic : Icons.mic_none,
                              color: isListening ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              if (isListening) {
                                _speech.stop();
                                setState(() => isListening = false);
                              } else {
                                _startListening();
                              }
                            },
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? "Ce champ est obligatoire"
                                : null,
                      ),

                      const SizedBox(height: 20),

                      // 🔥 CATEGORY
                      _buildLabel("Category *"),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedCategory = val!;
                          });
                        },
                        decoration: _inputDecoration("Select category", Icons.category),
                      ),

                      const SizedBox(height: 18),

                      // 🔥 QUANTITY + UNIT
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: bulkQtyController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration("Quantity", Icons.scale),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedUnit,
                              items: units
                                  .map((u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() => selectedUnit = v!);
                              },
                              decoration: _inputDecoration("", null),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 🔥 PRICE
                      _buildLabel("Sale Price (per Kg) *"),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Price in DH", Icons.payments_outlined),
                      ),

                      const SizedBox(height: 18),

                      // 🔥 DESCRIPTION
                      _buildLabel("Description *"),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: _inputDecoration("Details...", Icons.description_outlined),
                      ),

                      const SizedBox(height: 35),
                      _buildSubmitButton(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 30,
                right: 25,
                child: GestureDetector(
                  onTap: _showAISheet,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15),
                      ],
                    ),
                    child: const Icon(Icons.psychology, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _showImageSourceOptions,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _imageBytesList.isEmpty
            ? const Icon(Icons.add_a_photo)
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageBytesList.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.memory(
                    _imageBytesList[i],
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _animationController.dispose();
    nameController.dispose();
    priceController.dispose();
    bulkQtyController.dispose();
    stockController.dispose();
    descController.dispose();
    costController.dispose();
    otherCategoryController.dispose();
    super.dispose();
  }
}