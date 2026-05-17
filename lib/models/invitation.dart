class Invitation {
  final String id;
  final String fromUserId;
  final String toEmail;
  final String houseId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fromUserNickname;
  final String? houseName;

  Invitation({
    required this.id,
    required this.fromUserId,
    required this.toEmail,
    required this.houseId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fromUserNickname,
    this.houseName,
  });

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] as String,
      fromUserId: map['from_user_id'] as String,
      toEmail: map['to_email'] as String,
      houseId: map['house_id'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      fromUserNickname: map['from_user_nickname'] as String?,
      houseName: map['house_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_email': toEmail,
      'house_id': houseId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Invitation copyWith({
    String? id,
    String? fromUserId,
    String? toEmail,
    String? houseId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fromUserNickname,
    String? houseName,
  }) {
    return Invitation(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toEmail: toEmail ?? this.toEmail,
      houseId: houseId ?? this.houseId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fromUserNickname: fromUserNickname ?? this.fromUserNickname,
      houseName: houseName ?? this.houseName,
    );
  }
}
