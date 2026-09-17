import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../models/stock_movement.dart';

class StockRepository {
  StockRepository._();
  static final StockRepository instance = StockRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<int> addStock({
    required int productId,
    required int userId,
    required double quantity,
    String notes = '',
  }) async {
    final db = await _db;
    return db.transaction<int>((txn) async {
      // Catat movement
      final id = await txn.insert('stock_movements', {
        'product_id': productId,
        'user_id': userId,
        'quantity': quantity,
        'type': 'in',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });
      // Update stok produk
      await txn.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [quantity, productId],
      );
      return id;
    });
  }

  Future<List<StockMovement>> getByProduct(int productId) async {
    final db = await _db;
    final rows = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
      limit: 100,
    );
    return rows.map(StockMovement.fromMap).toList();
  }
}
