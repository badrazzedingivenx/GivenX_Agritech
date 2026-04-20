enum PaymentStatus {
  pending,
  held,       // money held in escrow
  released,   // released to farmer after delivery confirmed
  refunded,
  failed;

  String toJson() => name;

  static PaymentStatus fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'held':
      case 'escrow':
        return PaymentStatus.held;
      case 'released':
      case 'completed':
        return PaymentStatus.released;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.held:
        return 'In Escrow';
      case PaymentStatus.released:
        return 'Released';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }
}

enum PaymentMethod {
  online,
  bankTransfer,
  cashOnDelivery;

  String toJson() => name;

  static PaymentMethod fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'online':
        return PaymentMethod.online;
      case 'banktransfer':
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'cashondelivery':
      case 'cash_on_delivery':
      case 'cod':
        return PaymentMethod.cashOnDelivery;
      default:
        return PaymentMethod.online;
    }
  }
}

class Payment {
  final int? id;
  final int orderId;
  final int buyerId;
  final int farmerId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? escrowHeldAt;
  final DateTime? releasedAt;

  const Payment({
    this.id,
    required this.orderId,
    required this.buyerId,
    required this.farmerId,
    required this.amount,
    this.method = PaymentMethod.online,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    this.escrowHeldAt,
    this.releasedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int?,
      orderId: json['orderId'] as int? ?? 0,
      buyerId: json['buyerId'] as int? ?? 0,
      farmerId: json['farmerId'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: PaymentMethod.fromJson(json['method'] as String?),
      status: PaymentStatus.fromJson(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      escrowHeldAt: json['escrowHeldAt'] != null
          ? DateTime.parse(json['escrowHeldAt'] as String)
          : null,
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'orderId': orderId,
      'buyerId': buyerId,
      'farmerId': farmerId,
      'amount': amount,
      'method': method.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      if (escrowHeldAt != null)
        'escrowHeldAt': escrowHeldAt!.toIso8601String(),
      if (releasedAt != null) 'releasedAt': releasedAt!.toIso8601String(),
    };
  }

  Payment copyWith({
    int? id,
    int? orderId,
    int? buyerId,
    int? farmerId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? escrowHeldAt,
    DateTime? releasedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      escrowHeldAt: escrowHeldAt ?? this.escrowHeldAt,
      releasedAt: releasedAt ?? this.releasedAt,
    );
  }

  @override
  String toString() =>
      'Payment(id: $id, orderId: $orderId, status: $status, amount: $amount)';
}
