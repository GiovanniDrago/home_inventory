class OpfCredentials {
  final String username;
  final String password;

  OpfCredentials({required this.username, required this.password});

  factory OpfCredentials.fromMap(Map<String, dynamic> map) {
    return OpfCredentials(
      username: map['username'] as String,
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
    };
  }
}
