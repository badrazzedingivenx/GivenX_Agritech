import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class AddProductViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  bool isSuccess = false;

  String selectedUnit = 'Kg';
  String selectedCategory = 'Vegetable';
  bool isOrganic = false;
  bool isUrgent = false;

  final List<String> units = ['Kg', 'Bag (50kg)', 'Bag (25kg)', 'Ton'];
  final List<String> categories = ['Vegetable', 'Fruit', 'Grains', 'Others'];

  List<Uint8List> imageBytesList = [];

  double computeStock(String bulkQtyText) {
    double qty = double.tryParse(bulkQtyText) ?? 0;
    double factor = 1.0;
    if (selectedUnit == 'Bag (50kg)') factor = 50;
    else if (selectedUnit == 'Bag (25kg)') factor = 25;
    else if (selectedUnit == 'Ton') factor = 1000;
    return qty * factor;
  }

  void setUnit(String unit) {
    selectedUnit = unit;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void toggleOrganic(bool value) {
    isOrganic = value;
    notifyListeners();
  }

  void toggleUrgent(bool value) {
    isUrgent = value;
    notifyListeners();
  }

  void addImage(Uint8List bytes) {
    if (imageBytesList.length < 3) {
      imageBytesList = List.from(imageBytesList)..add(bytes);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    imageBytesList = List.from(imageBytesList)..removeAt(index);
    notifyListeners();
  }

  Future<void> saveProduct({
    required String name,
    required double price,
    required double quantity,
    required String description,
    required String location,
    String? otherCategory,
  }) async {
    isLoading = true;
    errorMessage = null;
    isSuccess = false;
    notifyListeners();

    try {
      final user = await SessionService.getUser();
      final category =
          selectedCategory == 'Others' && (otherCategory?.isNotEmpty ?? false)
              ? otherCategory!
              : selectedCategory;

      final images = imageBytesList
          .map((bytes) => base64Encode(bytes))
          .toList();

      final productData = {
        'name': name,
        'price': price,
        'quantity': quantity,
        'location': location,
        'unit': selectedUnit,
        'category': category.toLowerCase(),
        'description': description,
        'isOrganic': isOrganic,
        'isUrgent': isUrgent,
        'isAvailable': true,
        'farmerId': user?.id,
        'farmerName': user?.fullName ?? '',
        'images': images,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await ApiService.createProduct(productData);
      isSuccess = true;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
