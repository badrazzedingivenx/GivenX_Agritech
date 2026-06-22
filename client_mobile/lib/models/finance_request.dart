/// A financing request submitted by a Farmer and reviewed by a Bank.
///
/// Core fields (id, farmerId, amount, purpose, status, reviewedBy, createdAt,
/// notes) are required by the domain model. The descriptive fields
/// (farmerName, farmerCity, farmerPhone, title, description) are denormalized
/// snapshots persisted alongside the request so the bank can display it
/// without an extra user lookup.
class FinanceRequest {
  final String id;
  final String farmerId;
  final double amount;
  final String purpose;
  final String status; // pending / reviewing / approved / rejected
  final String? reviewedBy; // bankId of the reviewer
  final DateTime createdAt;
  final String? notes;

  // Denormalized display fields (present in db.json).
  final String farmerName;
  final String farmerCity;
  final String farmerPhone;
  final String title;
  final String description;

  const FinanceRequest({
    this.id = '',
    required this.farmerId,
    required this.amount,
    this.purpose = 'other',
    this.status = 'pending',
    this.reviewedBy,
    required this.createdAt,
    this.notes,
    this.farmerName = '',
    this.farmerCity = '',
    this.farmerPhone = '',
    this.title = '',
    this.description = '',
  });

  factory FinanceRequest.fromJson(Map<String, dynamic> json) {
    return FinanceRequest(
      id: json['id']?.toString() ?? '',
      farmerId: json['farmerId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      purpose: json['purpose'] as String? ?? 'other',
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewedBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      notes: json['notes'] as String?,
      farmerName: json['farmerName'] as String? ?? '',
      farmerCity: json['farmerCity'] as String? ?? '',
      farmerPhone: json['farmerPhone'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'farmerId': farmerId,
      'amount': amount,
      'purpose': purpose,
      'status': status,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      'createdAt': createdAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      'farmerName': farmerName,
      'farmerCity': farmerCity,
      'farmerPhone': farmerPhone,
      'title': title,
      'description': description,
    };
  }

  FinanceRequest copyWith({
    String? id,
    String? farmerId,
    double? amount,
    String? purpose,
    String? status,
    String? reviewedBy,
    DateTime? createdAt,
    String? notes,
    String? farmerName,
    String? farmerCity,
    String? farmerPhone,
    String? title,
    String? description,
  }) {
    return FinanceRequest(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      farmerName: farmerName ?? this.farmerName,
      farmerCity: farmerCity ?? this.farmerCity,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  /// Numeric id helper for REST endpoints that key on int ids.
  int? get numericId => int.tryParse(id);

  @override
  String toString() =>
      'FinanceRequest(id: $id, farmer: $farmerId, amount: $amount, status: $status)';
}
