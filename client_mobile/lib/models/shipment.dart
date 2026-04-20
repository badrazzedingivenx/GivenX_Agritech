enum ShipmentStatus {
  requested,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  cancelled;

  String toJson() => name;

  static ShipmentStatus fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'requested':
        return ShipmentStatus.requested;
      case 'accepted':
        return ShipmentStatus.accepted;
      case 'pickedup':
      case 'picked_up':
        return ShipmentStatus.pickedUp;
      case 'intransit':
      case 'in_transit':
      case 'in transit':
        return ShipmentStatus.inTransit;
      case 'delivered':
        return ShipmentStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return ShipmentStatus.cancelled;
      default:
        return ShipmentStatus.requested;
    }
  }

  String get label {
    switch (this) {
      case ShipmentStatus.requested:
        return 'Requested';
      case ShipmentStatus.accepted:
        return 'Accepted';
      case ShipmentStatus.pickedUp:
        return 'Picked Up';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Shipment {
  final int? id;
  final int orderId;
  final int farmerId;
  final String farmerName;
  final int? transporterId;
  final String? transporterName;
  final String pickupLocation;
  final String deliveryLocation;
  final ShipmentStatus status;
  final double? weight; // in Kg
  final String? vehicleType;
  final double? estimatedDistance; // in Km
  final DateTime? pickupDate;
  final DateTime? estimatedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? trackingNote;
  final DateTime createdAt;

  const Shipment({
    this.id,
    required this.orderId,
    required this.farmerId,
    this.farmerName = '',
    this.transporterId,
    this.transporterName,
    required this.pickupLocation,
    required this.deliveryLocation,
    this.status = ShipmentStatus.requested,
    this.weight,
    this.vehicleType,
    this.estimatedDistance,
    this.pickupDate,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
    this.trackingNote,
    required this.createdAt,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] as int?,
      orderId: json['orderId'] as int? ?? 0,
      farmerId: json['farmerId'] as int? ?? 0,
      farmerName: json['farmerName'] as String? ?? '',
      transporterId: json['transporterId'] as int?,
      transporterName: json['transporterName'] as String?,
      pickupLocation: json['pickupLocation'] as String? ?? '',
      deliveryLocation: json['deliveryLocation'] as String? ?? '',
      status: ShipmentStatus.fromJson(json['status'] as String?),
      weight: (json['weight'] as num?)?.toDouble(),
      vehicleType: json['vehicleType'] as String?,
      estimatedDistance: (json['estimatedDistance'] as num?)?.toDouble(),
      pickupDate: json['pickupDate'] != null
          ? DateTime.parse(json['pickupDate'] as String)
          : null,
      estimatedDeliveryDate: json['estimatedDeliveryDate'] != null
          ? DateTime.parse(json['estimatedDeliveryDate'] as String)
          : null,
      actualDeliveryDate: json['actualDeliveryDate'] != null
          ? DateTime.parse(json['actualDeliveryDate'] as String)
          : null,
      trackingNote: json['trackingNote'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'orderId': orderId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      if (transporterId != null) 'transporterId': transporterId,
      if (transporterName != null) 'transporterName': transporterName,
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'status': status.toJson(),
      if (weight != null) 'weight': weight,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (estimatedDistance != null) 'estimatedDistance': estimatedDistance,
      if (pickupDate != null) 'pickupDate': pickupDate!.toIso8601String(),
      if (estimatedDeliveryDate != null)
        'estimatedDeliveryDate': estimatedDeliveryDate!.toIso8601String(),
      if (actualDeliveryDate != null)
        'actualDeliveryDate': actualDeliveryDate!.toIso8601String(),
      if (trackingNote != null) 'trackingNote': trackingNote,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Shipment copyWith({
    int? id,
    int? orderId,
    int? farmerId,
    String? farmerName,
    int? transporterId,
    String? transporterName,
    String? pickupLocation,
    String? deliveryLocation,
    ShipmentStatus? status,
    double? weight,
    String? vehicleType,
    double? estimatedDistance,
    DateTime? pickupDate,
    DateTime? estimatedDeliveryDate,
    DateTime? actualDeliveryDate,
    String? trackingNote,
    DateTime? createdAt,
  }) {
    return Shipment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      transporterId: transporterId ?? this.transporterId,
      transporterName: transporterName ?? this.transporterName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      status: status ?? this.status,
      weight: weight ?? this.weight,
      vehicleType: vehicleType ?? this.vehicleType,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      pickupDate: pickupDate ?? this.pickupDate,
      estimatedDeliveryDate:
          estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      trackingNote: trackingNote ?? this.trackingNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Shipment(id: $id, orderId: $orderId, status: $status)';
}
