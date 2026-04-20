enum OrderStatus {
  pending,
  confirmed,
  processing,
  inTransit,
  delivered,
  cancelled;

  String toJson() => name;

  static OrderStatus fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'intransit':
      case 'in_transit':
      case 'in transit':
        return OrderStatus.inTransit;
      case 'delivered':
      case 'completed':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final double quantity;
  final String unit;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.unit = 'Kg',
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'Kg',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class Order {
  final int? id;
  final int buyerId;
  final String buyerName;
  final int farmerId;
  final String farmerName;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final int? shipmentId;
  final int? paymentId;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    this.id,
    required this.buyerId,
    this.buyerName = '',
    required this.farmerId,
    this.farmerName = '',
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.shipmentId,
    this.paymentId,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      buyerId: json['buyerId'] as int? ?? 0,
      buyerName: json['buyerName'] as String? ?? '',
      farmerId: json['farmerId'] as int? ?? 0,
      farmerName: json['farmerName'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromJson(json['status'] as String?),
      shipmentId: json['shipmentId'] as int?,
      paymentId: json['paymentId'] as int?,
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.toJson(),
      if (shipmentId != null) 'shipmentId': shipmentId,
      if (paymentId != null) 'paymentId': paymentId,
      if (note != null) 'note': note,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Order copyWith({
    int? id,
    int? buyerId,
    String? buyerName,
    int? farmerId,
    String? farmerName,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    int? shipmentId,
    int? paymentId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      shipmentId: shipmentId ?? this.shipmentId,
      paymentId: paymentId ?? this.paymentId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Order(id: $id, status: $status, total: $totalAmount)';
}
