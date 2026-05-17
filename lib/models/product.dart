class Product {
  final String id;
  final String name;
  final String? brand;
  final String? note;
  final int quantity;
  final double? price;
  final String roomId;
  final String? categoryId;
  final String houseId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.brand,
    this.note,
    required this.quantity,
    this.price,
    required this.roomId,
    this.categoryId,
    required this.houseId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      note: map['note'] as String?,
      quantity: map['quantity'] as int,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      roomId: map['room_id'] as String,
      categoryId: map['category_id'] as String?,
      houseId: map['house_id'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'note': note,
      'quantity': quantity,
      'price': price,
      'room_id': roomId,
      'category_id': categoryId,
      'house_id': houseId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? note,
    int? quantity,
    double? price,
    String? roomId,
    String? categoryId,
    String? houseId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      note: note ?? this.note,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      roomId: roomId ?? this.roomId,
      categoryId: categoryId ?? this.categoryId,
      houseId: houseId ?? this.houseId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
