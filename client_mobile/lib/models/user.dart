/// Roles available in the system.
enum UserRole {
  farmer,
  buyer,
  transporter,
  bank,
  admin;

  String toJson() => name;

  static UserRole fromJson(String value) {
    // Support both English keys and legacy French labels from db.json
    switch (value.toLowerCase()) {
      case 'farmer':
      case 'agriculteur':
        return UserRole.farmer;
      case 'buyer':
      case 'usine':
      case 'restaurant':
      case 'industry':
        return UserRole.buyer;
      case 'transporter':
      case 'transporteur':
        return UserRole.transporter;
      case 'bank':
      case 'banque':
        return UserRole.bank;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.buyer;
    }
  }
}

/// Buyer sub-types: Restaurant or Industry.
enum BuyerType {
  restaurant,
  industry;

  String toJson() => name;

  static BuyerType fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'restaurant':
        return BuyerType.restaurant;
      case 'industry':
      case 'usine':
        return BuyerType.industry;
      default:
        return BuyerType.restaurant;
    }
  }
}

class User {
  final int? id;
  final String email;
  final String fullName;
  final String phone;
  final String city;
  final UserRole role;

  // Buyer-specific
  final BuyerType? buyerType;

  // Farmer-specific
  final String? farmingType;
  final String? mainProducts;

  // Buyer / Industry-specific
  final String? companyName;
  final String? productTypes;

  // Restaurant-specific
  final String? cuisineType;
  final String? dailyOrderVolume;
  final String? deliveryFrequency;

  // Industry-specific
  final String? industryType;
  final String? monthlyVolume;
  final String? storageCapacity;
  final String? certification;
  final String? logisticsPreference;

  // Transporter-specific
  final String? vehicleType;
  final String? capacity;

  // Bank-specific
  final String? bankName;
  final String? officialId;
  final String? logoPath;
  final String? bankType;
  final String? servicesOffered;

  // Auth
  final String? token;
  final bool isVerified;

  const User({
    this.id,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.city = '',
    required this.role,
    this.buyerType,
    this.farmingType,
    this.mainProducts,
    this.companyName,
    this.productTypes,
    this.cuisineType,
    this.dailyOrderVolume,
    this.deliveryFrequency,
    this.industryType,
    this.monthlyVolume,
    this.storageCapacity,
    this.certification,
    this.logisticsPreference,
    this.vehicleType,
    this.capacity,
    this.bankName,
    this.officialId,
    this.logoPath,
    this.bankType,
    this.servicesOffered,
    this.token,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final role = UserRole.fromJson(json['role'] as String? ?? 'buyer');
    return User(
      id: json['id'] as int?,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      role: role,
      buyerType: role == UserRole.buyer
          ? BuyerType.fromJson(json['buyerType'] as String?)
          : null,
      farmingType: json['farmingType'] as String?,
      mainProducts: json['mainProducts'] as String?,
      companyName: json['companyName'] as String?,
      productTypes: json['productTypes'] as String?,
      cuisineType: json['cuisineType'] as String?,
      dailyOrderVolume: json['dailyOrderVolume'] as String?,
      deliveryFrequency: json['deliveryFrequency'] as String?,
      industryType: json['industryType'] as String?,
      monthlyVolume: json['monthlyVolume'] as String?,
      storageCapacity: json['storageCapacity'] as String?,
      certification: json['certification'] as String?,
      logisticsPreference: json['logisticsPreference'] as String?,
      vehicleType: json['vehicleType'] as String?,
      capacity: json['capacity'] as String?,
      bankName: json['bankName'] as String?,
      officialId: json['officialId'] as String?,
      logoPath: json['logoPath'] as String?,
      bankType: json['bankType'] as String?,
      servicesOffered: json['servicesOffered'] as String?,
      token: json['token'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'city': city,
      'role': role.toJson(),
      if (buyerType != null) 'buyerType': buyerType!.toJson(),
      if (farmingType != null) 'farmingType': farmingType,
      if (mainProducts != null) 'mainProducts': mainProducts,
      if (companyName != null) 'companyName': companyName,
      if (productTypes != null) 'productTypes': productTypes,
      if (cuisineType != null) 'cuisineType': cuisineType,
      if (dailyOrderVolume != null) 'dailyOrderVolume': dailyOrderVolume,
      if (deliveryFrequency != null) 'deliveryFrequency': deliveryFrequency,
      if (industryType != null) 'industryType': industryType,
      if (monthlyVolume != null) 'monthlyVolume': monthlyVolume,
      if (storageCapacity != null) 'storageCapacity': storageCapacity,
      if (certification != null) 'certification': certification,
      if (logisticsPreference != null) 'logisticsPreference': logisticsPreference,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (capacity != null) 'capacity': capacity,
      if (bankName != null) 'bankName': bankName,
      if (officialId != null) 'officialId': officialId,
      if (logoPath != null) 'logoPath': logoPath,
      if (bankType != null) 'bankType': bankType,
      if (servicesOffered != null) 'servicesOffered': servicesOffered,
      if (token != null) 'token': token,
      'isVerified': isVerified,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phone,
    String? city,
    UserRole? role,
    BuyerType? buyerType,
    String? farmingType,
    String? mainProducts,
    String? companyName,
    String? productTypes,
    String? cuisineType,
    String? dailyOrderVolume,
    String? deliveryFrequency,
    String? industryType,
    String? monthlyVolume,
    String? storageCapacity,
    String? certification,
    String? logisticsPreference,
    String? vehicleType,
    String? capacity,
    String? bankName,
    String? officialId,
    String? logoPath,
    String? bankType,
    String? servicesOffered,
    String? token,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      role: role ?? this.role,
      buyerType: buyerType ?? this.buyerType,
      farmingType: farmingType ?? this.farmingType,
      mainProducts: mainProducts ?? this.mainProducts,
      companyName: companyName ?? this.companyName,
      productTypes: productTypes ?? this.productTypes,
      cuisineType: cuisineType ?? this.cuisineType,
      dailyOrderVolume: dailyOrderVolume ?? this.dailyOrderVolume,
      deliveryFrequency: deliveryFrequency ?? this.deliveryFrequency,
      industryType: industryType ?? this.industryType,
      monthlyVolume: monthlyVolume ?? this.monthlyVolume,
      storageCapacity: storageCapacity ?? this.storageCapacity,
      certification: certification ?? this.certification,
      logisticsPreference: logisticsPreference ?? this.logisticsPreference,
      vehicleType: vehicleType ?? this.vehicleType,
      capacity: capacity ?? this.capacity,
      bankName: bankName ?? this.bankName,
      officialId: officialId ?? this.officialId,
      logoPath: logoPath ?? this.logoPath,
      bankType: bankType ?? this.bankType,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      token: token ?? this.token,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, role: $role)';
}
