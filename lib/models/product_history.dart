class ProductHistory {
  final String id;
  final String productId;
  final String action;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  ProductHistory({
    required this.id,
    required this.productId,
    required this.action,
    this.details,
    required this.createdAt,
  });

  factory ProductHistory.fromMap(Map<String, dynamic> map) {
    return ProductHistory(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      action: map['action'] as String,
      details: map['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'action': action,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
