import 'package:flutter/material.dart';

import '../core/security/hash.dart';
import '../core/database/db_helper.dart';
import '../models/user.dart';

class UserViewModel extends ChangeNotifier {
  List<User> _items = [];
  bool _loading = false;

  List<User> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final db = await DbHelper.instance.database;
      final rows = await db.query('users', orderBy: 'username ASC');
      _items = rows.map(User.fromMap).toList();
    } catch (_) {
      _items = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final db = await DbHelper.instance.database;
    await db.insert('users', {
      'username': username,
      'password_hash': Hash.sha256(password),
      'full_name': fullName,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    });
    await load();
  }

  Future<void> updateUser({
    required int id,
    required String fullName,
    required String role,
    String? newPassword,
  }) async {
    final db = await DbHelper.instance.database;
    final data = <String, Object?>{
      'full_name': fullName,
      'role': role,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      data['password_hash'] = Hash.sha256(newPassword);
    }
    await db.update('users', data, where: 'id = ?', whereArgs: [id]);
    await load();
  }

  Future<void> delete(int id, {required int currentUserId}) async {
    if (id == currentUserId) {
      throw Exception('Tidak bisa menghapus akun yang sedang login.');
    }
    final db = await DbHelper.instance.database;
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
    await load();
  }

  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final db = await DbHelper.instance.database;
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
