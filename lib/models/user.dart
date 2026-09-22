class User {
  final int? id;
  final String username;
  final String? passwordHash;
  final String? passwordSalt;
  final String fullName;
  final String role;

  const User({
    this.id,
    required this.username,
    this.passwordHash,
    this.passwordSalt,
    required this.fullName,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String?,
      passwordSalt: map['password_salt'] as String?,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordSalt != null) 'password_salt': passwordSalt,
      'full_name': fullName,
      'role': role,
    };
  }
}
