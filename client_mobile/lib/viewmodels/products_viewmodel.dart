import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class ProductsViewModel extends ChangeNotifier {
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? error;
  List<Product> products = [];

  // Pagination (json-server _page/_limit)
  static const int pageSize = 10;
  int _page = 1;

  String searchQuery = '';
  String selectedCategory = 'All';
  String sortBy = 'Name';

  final List<String> categories = ['All', 'Vegetables', 'Fruits', 'Grains'];
  final List<String> units = ['Kg', 'Ton', 'Gram', 'Piece'];

  List<Product> get filteredProducts {
    List<Product> list = products.where((product) {
      final catName = product.category.name[0].toUpperCase() +
          product.category.name.substring(1);
      final matchesCategory =
          selectedCategory == 'All' || catName == selectedCategory;
      final matchesSearch =
          product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (sortBy == 'Price') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == 'Stock') {
      list.sort((a, b) => a.quantity.compareTo(b.quantity));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  int get lowStockCount => products.where((p) => p.quantity < 5).length;

  Future<void> loadProducts() async {
    isLoading = true;
    error = null;
    _page = 1;
    hasMore = true;
    notifyListeners();
    try {
      final user = await SessionService.getUser();
      final sellerId = user?.id?.toString();
      final data = await ApiService.getProducts(
        sellerId: sellerId,
        page: _page,
        limit: pageSize,
      );
      products = data
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      hasMore = data.length >= pageSize;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the next page and appends to [products] ("Charger plus").
  Future<void> loadMore() async {
    if (isLoadingMore || isLoading || !hasMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final user = await SessionService.getUser();
      final sellerId = user?.id?.toString();
      final nextPage = _page + 1;
      final data = await ApiService.getProducts(
        sellerId: sellerId,
        page: nextPage,
        limit: pageSize,
      );
      final more = data
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      products.addAll(more);
      _page = nextPage;
      hasMore = more.length >= pageSize;
    } catch (_) {
      // keep existing items on failure
    }
    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await ApiService.deleteProduct(id);
    products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    sortBy = sort;
    notifyListeners();
  }
}
