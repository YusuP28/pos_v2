import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository._();
  static final CategoryRepository instance = CategoryRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<List<Category>> getAll() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insert(Category c) async {
    final db = await _db;
    return db.insert('categories', {
      'name': c.name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> update(Category c) async {
    final db = await _db;
    await db.update(
      'categories',
      {'name': c.name},
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
