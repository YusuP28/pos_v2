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
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, Hash.sha256(password)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }
}
