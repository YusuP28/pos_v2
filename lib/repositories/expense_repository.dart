import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository._();
  static final ExpenseRepository instance = ExpenseRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<int> insert(Expense e) async {
    final db = await _db;
    return db.insert('expenses', e.toMap());
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getByShift(int shiftId) async {
    final db = await _db;
    final rows = await db.query(
      'expenses',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<double> totalByShift(int shiftId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE shift_id = ?',
      [shiftId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Expense>> getRecent({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      'expenses',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Expense.fromMap).toList();
  }
}
