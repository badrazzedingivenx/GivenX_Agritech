import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';

class ProfileFarmerPage extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String farmingType;
  final String mainProducts;

  const ProfileFarmerPage({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.farmingType,
    required this.mainProducts,
  });

  @override
  State<ProfileFarmerPage> createState() => _ProfileFarmerPageState();
}

class _ProfileFarmerPageState extends State<ProfileFarmerPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  int _productCount = 0;
  int _orderCount = 0;
  double _avgRating = 0.0;
  int _reviewCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final user = await SessionService.getUser();
      final farmerId = user?.id;
      final results = await Future.wait([
        ApiService.getProducts(sellerId: farmerId?.toString()),
        ApiService.getOrders(farmerId: farmerId?.toString()),
        ApiService.getReviews(targetUserId: farmerId?.toString()),
      ]);
      if (mounted) {
        final reviews = results[2] as List<dynamic>;
        double avg = 0;
        if (reviews.isNotEmpty) {
          avg = reviews.fold<double>(0, (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0)) / reviews.length;
        }
        setState(() {
          _productCount = results[0].length;
          _orderCount = results[1].length;
          _avgRating = avg;
          _reviewCount = reviews.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Profile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text("Change Photo"),
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit Info"),
              ),
              ListTile(
                leading: Icon(Icons.lock),
                title: Text("Change Password"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditSheet,
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 25, bottom: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [

                  /// 👨 PROFILE IMAGE + CAMERA
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2E7D32),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: const Color(0xFF1B5E20).withValues(alpha: 0.15),
                          backgroundImage:
                              _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? const Icon(Icons.person,
                                  size: 55, color: Color(0xFF1B5E20))
                              : null,
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    widget.farmingType,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat("Products", _loading ? "..." : "$_productCount"),
                      _stat("Orders", _loading ? "..." : "$_orderCount"),
                      _stat("Rating", _loading ? "..." : _reviewCount > 0 ? _avgRating.toStringAsFixed(1) : "N/A"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            _title("Account Information"),

            _card(Icons.email, "Email", widget.email),
            _card(Icons.phone, "Phone", widget.phone),
            _card(Icons.location_city, "City", widget.city),

            const SizedBox(height: 10),

            _title("Farm Details"),

            _card(Icons.eco, "Farming Type", widget.farmingType),
            _card(Icons.agriculture, "Products", widget.mainProducts),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// ================= UI HELPERS =================
  Widget _stat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 3),
        Text(title,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _card(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}