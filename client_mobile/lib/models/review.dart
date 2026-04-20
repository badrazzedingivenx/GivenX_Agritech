class Review {
  final int? id;
  final int reviewerId;
  final String reviewerName;
  final int targetUserId; // farmer or transporter being reviewed
  final String targetUserName;
  final int? orderId;
  final double rating; // 1.0 – 5.0
  final String comment;
  final DateTime createdAt;

  const Review({
    this.id,
    required this.reviewerId,
    this.reviewerName = '',
    required this.targetUserId,
    this.targetUserName = '',
    this.orderId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int?,
      reviewerId: json['reviewerId'] as int? ?? 0,
      reviewerName: json['reviewerName'] as String? ?? '',
      targetUserId: json['targetUserId'] as int? ?? 0,
      targetUserName: json['targetUserName'] as String? ?? '',
      orderId: json['orderId'] as int?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      if (orderId != null) 'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    int? id,
    int? reviewerId,
    String? reviewerName,
    int? targetUserId,
    String? targetUserName,
    int? orderId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Review(id: $id, rating: $rating, target: $targetUserId)';
}
