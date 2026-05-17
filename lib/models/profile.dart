class Profile {
  final String id;
  final String nickname;
  final String email;
  final String? houseId;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.nickname,
    required this.email,
    this.houseId,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      nickname: map['nickname'] as String,
      email: map['email'] as String,
      houseId: map['house_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'email': email,
      'house_id': houseId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? nickname,
    String? email,
    String? houseId,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      houseId: houseId ?? this.houseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
