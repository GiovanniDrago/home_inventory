class Room {
  final String id;
  final String name;
  final String houseId;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.houseId,
    required this.createdAt,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as String,
      name: map['name'] as String,
      houseId: map['house_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'house_id': houseId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Room copyWith({
    String? id,
    String? name,
    String? houseId,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      houseId: houseId ?? this.houseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
