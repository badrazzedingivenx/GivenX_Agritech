enum ProductCategory {
  vegetables,
  fruits,
  grains,
  stock,
  seeds,
  machines,
  tools,
  dairy,
  other;

  String toJson() => name;

  static ProductCategory fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'vegetables':
        return ProductCategory.vegetables;
      case 'fruits':
        return ProductCategory.fruits;
      case 'grains':
        return ProductCategory.grains;
      case 'stock':
        return ProductCategory.stock;
      case 'seeds':
        return ProductCategory.seeds;
      case 'machines':
        return ProductCategory.machines;
      case 'tools':
        return ProductCategory.tools;
      case 'dairy':
        return ProductCategory.dairy;
      default:
        return ProductCategory.other;
    }
  }
}

class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String unit; // Kg, Ton, Piece, etc.
  final double quantity;
  final ProductCategory category;
  final String location; // origin city
  final int farmerId;
  final String farmerName;
  final String? image;
  final List<String> images;
  final bool isOrganic;
  final bool isUrgent;
  final bool isAvailable;
  final DateTime createdAt;

  const Product({
    this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.unit = 'Kg',
    required this.quantity,
    this.category = ProductCategory.other,
    required this.location,
    required this.farmerId,
    this.farmerName = '',
    this.image,
    this.images = const [],
    this.isOrganic = false,
    this.isUrgent = false,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'Kg',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      category: ProductCategory.fromJson(json['category'] as String?),
      location: json['location'] as String? ?? '',
      farmerId: json['farmerId'] as int? ?? 0,
      farmerName: json['farmerName'] as String? ?? '',
      image: json['image'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isOrganic: json['isOrganic'] as bool? ?? false,
      isUrgent: json['isUrgent'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'category': category.toJson(),
      'location': location,
      'farmerId': farmerId,
      'farmerName': farmerName,
      if (image != null) 'image': image,
      'images': images,
      'isOrganic': isOrganic,
      'isUrgent': isUrgent,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? unit,
    double? quantity,
    ProductCategory? category,
    String? location,
    int? farmerId,
    String? farmerName,
    String? image,
    List<String>? images,
    bool? isOrganic,
    bool? isUrgent,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      location: location ?? this.location,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      image: image ?? this.image,
      images: images ?? this.images,
      isOrganic: isOrganic ?? this.isOrganic,
      isUrgent: isUrgent ?? this.isUrgent,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';
}
