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
    final check = Hash.checkPassword(
      password,
      hash: user.passwordHash ?? '',
      salt: user.passwordSalt ?? '',
    );
    if (check == PasswordCheck.mismatch) return null;

    // Migrasi otomatis SHA-256 → PBKDF2 + salt baru, sekali saat login.
    if (check == PasswordCheck.matchLegacy && user.id != null) {
      await _storePassword(db, user.id!, password);
    }
    return user;
  }

  /// Tulis hash PBKDF2 + salt baru untuk satu user.
  Future<void> _storePassword(
    DatabaseExecutor db,
    int userId,
    String password,
  ) async {
    final hashed = Hash.hashPassword(password);
    await db.update(
      'users',
      {
        'password_hash': hashed.hash,
        'password_salt': hashed.salt,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> create({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final db = await _db;
    final hashed = Hash.hashPassword(password);
    return db.insert('users', {
      'username': username,
      'password_hash': hashed.hash,
      'password_salt': hashed.salt,
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
      final hashed = Hash.hashPassword(newPassword);
      data['password_hash'] = hashed.hash;
      data['password_salt'] = hashed.salt;
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
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('User tidak ditemukan.');
    }

    final user = User.fromMap(rows.first);
    final check = Hash.checkPassword(
      oldPassword,
      hash: user.passwordHash ?? '',
      salt: user.passwordSalt ?? '',
    );
    if (check == PasswordCheck.mismatch) {
      throw Exception('Password lama salah.');
    }

    await _storePassword(db, userId, newPassword);
  }
}
