class User {
  final int? id;
  final String username;
  final String fullName;
  final String role;

  const User({
    this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
    };
  }
}
