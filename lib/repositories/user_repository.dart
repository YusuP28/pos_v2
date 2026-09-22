import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../core/security/hash.dart';
import '../models/user.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<User?> verify(String username, String password) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final user = User.fromMap(rows.first);
    final salt = user.passwordSalt ?? '';
    final hash = user.passwordHash ?? '';

    // PBKDF2 verify
    if (salt.isNotEmpty) {
      if (Hash.verify(password, salt, hash)) return user;
      return null;
    }

    // Legacy SHA256 fallback → auto-migrate
    if (hash == Hash.sha256(password)) {
      final newSalt = Hash.generateSalt();
      final newHash = Hash.pbkdf2(password, newSalt);
      await db.update(
        'users',
        {'password_hash': newHash, 'password_salt': newSalt},
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return user;
    }
    return null;
  }
}
