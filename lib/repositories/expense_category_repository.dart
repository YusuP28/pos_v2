import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';

class ExpenseCategoryRepository {
  ExpenseCategoryRepository._();
  static final ExpenseCategoryRepository instance =
      ExpenseCategoryRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<List<String>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'expense_categories',
      orderBy: 'is_default DESC, name ASC',
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<List<Map<String, Object?>>> getAllWithMeta() async {
    final db = await _db;
    return db.query(
      'expense_categories',
      orderBy: 'is_default DESC, name ASC',
    );
  }

  Future<void> add(String name) async {
    final db = await _db;
    await db.insert('expense_categories', {
      'name': name,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> delete(String name) async {
    final db = await _db;
    // Cek apakah kategori ini punya pengeluaran
    final cek = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM expenses WHERE category = ?',
      [name],
    );
    final count = (cek.first['c'] as int?) ?? 0;
    if (count > 0) {
      throw Exception(
          'Kategori "$name" sudah dipakai $count pengeluaran. Tidak bisa dihapus.');
    }
    // Hanya boleh hapus custom (is_default = 0)
    final rows = await db.query(
      'expense_categories',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isEmpty) return;
    if ((rows.first['is_default'] as int?) == 1) {
      throw Exception('Kategori default tidak bisa dihapus.');
    }
    await db.delete('expense_categories', where: 'name = ?', whereArgs: [name]);
  }
}
