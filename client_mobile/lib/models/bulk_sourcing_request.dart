enum BulkRequestStatus {
  open,
  inProgress,
  fulfilled,
  cancelled;

  String toJson() => name;

  static BulkRequestStatus fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'open':
        return BulkRequestStatus.open;
      case 'inprogress':
      case 'in_progress':
        return BulkRequestStatus.inProgress;
      case 'fulfilled':
      case 'completed':
        return BulkRequestStatus.fulfilled;
      case 'cancelled':
      case 'canceled':
        return BulkRequestStatus.cancelled;
      default:
        return BulkRequestStatus.open;
    }
  }

  String get label {
    switch (this) {
      case BulkRequestStatus.open:
        return 'Open';
      case BulkRequestStatus.inProgress:
        return 'In Progress';
      case BulkRequestStatus.fulfilled:
        return 'Fulfilled';
      case BulkRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// An offer from a farmer responding to a bulk sourcing request.
class BulkOffer {
  final int? id;
  final int farmerId;
  final String farmerName;
  final double pricePerUnit;
  final double availableQuantity;
  final String? note;
  final bool isAccepted;
  final DateTime createdAt;

  const BulkOffer({
    this.id,
    required this.farmerId,
    this.farmerName = '',
    required this.pricePerUnit,
    required this.availableQuantity,
    this.note,
    this.isAccepted = false,
    required this.createdAt,
  });

  factory BulkOffer.fromJson(Map<String, dynamic> json) {
    return BulkOffer(
      id: json['id'] as int?,
      farmerId: json['farmerId'] as int? ?? 0,
      farmerName: json['farmerName'] as String? ?? '',
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0,
      availableQuantity:
          (json['availableQuantity'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String?,
      isAccepted: json['isAccepted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'pricePerUnit': pricePerUnit,
      'availableQuantity': availableQuantity,
      if (note != null) 'note': note,
      'isAccepted': isAccepted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// A bulk sourcing request published by an Industry buyer.
class BulkSourcingRequest {
  final int? id;
  final int buyerId;
  final String buyerName;
  final String productName;
  final String category;
  final double requestedQuantity;
  final String unit; // Ton, Kg, etc.
  final double? maxBudgetPerUnit;
  final String? description;
  final DateTime deadline;
  final BulkRequestStatus status;
  final List<BulkOffer> offers;
  final DateTime createdAt;

  const BulkSourcingRequest({
    this.id,
    required this.buyerId,
    this.buyerName = '',
    required this.productName,
    this.category = '',
    required this.requestedQuantity,
    this.unit = 'Ton',
    this.maxBudgetPerUnit,
    this.description,
    required this.deadline,
    this.status = BulkRequestStatus.open,
    this.offers = const [],
    required this.createdAt,
  });

  factory BulkSourcingRequest.fromJson(Map<String, dynamic> json) {
    return BulkSourcingRequest(
      id: json['id'] as int?,
      buyerId: json['buyerId'] as int? ?? 0,
      buyerName: json['buyerName'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      requestedQuantity:
          (json['requestedQuantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'Ton',
      maxBudgetPerUnit:
          (json['maxBudgetPerUnit'] as num?)?.toDouble(),
      description: json['description'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : DateTime.now(),
      status: BulkRequestStatus.fromJson(json['status'] as String?),
      offers: (json['offers'] as List<dynamic>?)
              ?.map((e) => BulkOffer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'productName': productName,
      'category': category,
      'requestedQuantity': requestedQuantity,
      'unit': unit,
      if (maxBudgetPerUnit != null) 'maxBudgetPerUnit': maxBudgetPerUnit,
      if (description != null) 'description': description,
      'deadline': deadline.toIso8601String(),
      'status': status.toJson(),
      'offers': offers.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BulkSourcingRequest copyWith({
    int? id,
    int? buyerId,
    String? buyerName,
    String? productName,
    String? category,
    double? requestedQuantity,
    String? unit,
    double? maxBudgetPerUnit,
    String? description,
    DateTime? deadline,
    BulkRequestStatus? status,
    List<BulkOffer>? offers,
    DateTime? createdAt,
  }) {
    return BulkSourcingRequest(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      unit: unit ?? this.unit,
      maxBudgetPerUnit: maxBudgetPerUnit ?? this.maxBudgetPerUnit,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      offers: offers ?? this.offers,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'BulkSourcingRequest(id: $id, product: $productName, qty: $requestedQuantity $unit)';
}
