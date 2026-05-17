class Category {
  final String id;
  final String name;
  final String? description;
  final String houseId;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.houseId,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      houseId: map['house_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'house_id': houseId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? houseId,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      houseId: houseId ?? this.houseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
