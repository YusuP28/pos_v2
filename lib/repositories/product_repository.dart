import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<List<Product>> getAll({String query = ''}) async {
    final db = await _db;
    if (query.isEmpty) {
      final rows = await db.query(
        'products',
        where: 'is_active = 1',
        orderBy: 'name COLLATE NOCASE',
      );
      return rows.map(Product.fromMap).toList();
    }
    final rows = await db.query(
      'products',
      where:
          'is_active = 1 AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> findByBarcode(String barcode) async {
    final db = await _db;
    final rows = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<int> insert(Product p) async {
    final db = await _db;
    final map = p.toInsertMap();
    map['created_at'] = DateTime.now().toIso8601String();
    return db.insert('products', map);
  }

  Future<void> update(Product p) async {
    final db = await _db;
    await db.update(
      'products',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<void> softDelete(int id) async {
    final db = await _db;
    await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
