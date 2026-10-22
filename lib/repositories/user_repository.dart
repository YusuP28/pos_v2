import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../core/security/hash.dart';
import '../models/user.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<List<User>> getAll() async {
    final db = await _db;
    final rows = await db.query('users', orderBy: 'username ASC');
    return rows.map(User.fromMap).toList();
  }

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

  Future<int> create({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final db = await _db;
    return db.insert('users', {
      'username': username,
      'password_hash': Hash.sha256(password),
      'full_name': fullName,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateProfile({
    required int id,
    required String fullName,
    required String role,
    String? newPassword,
  }) async {
    final db = await _db;
    final data = <String, Object?>{
      'full_name': fullName,
      'role': role,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      data['password_hash'] = Hash.sha256(newPassword);
    }
    await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id, {required int currentUserId}) async {
    if (id == currentUserId) {
      throw Exception('Tidak bisa menghapus akun yang sedang login.');
    }
    final db = await _db;
    // Cek apakah user ini punya transaksi
    final cek = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM orders WHERE user_id = ?',
      [id],
    );
    final count = (cek.first['c'] as int?) ?? 0;
    if (count > 0) {
      throw Exception(
          'User ini punya $count transaksi. Tidak bisa dihapus. Nonaktifkan saja (ganti role).');
    }
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'id = ? AND password_hash = ?',
      whereArgs: [userId, Hash.sha256(oldPassword)],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('Password lama salah.');
    }
    await db.update(
      'users',
      {'password_hash': Hash.sha256(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
