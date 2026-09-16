import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../models/shift.dart';

class ShiftRepository {
  ShiftRepository._();
  static final ShiftRepository instance = ShiftRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<Shift?> getOpenShift() async {
    final db = await _db;
    final rows = await db.query(
      'shifts',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Shift.fromMap(rows.first);
  }

  Future<Shift?> getById(int id) async {
    final db = await _db;
    final rows =
        await db.query('shifts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Shift.fromMap(rows.first);
  }

  Future<int> openShift({
    required int userId,
    required double openingCash,
    String notes = '',
  }) async {
    final db = await _db;
    final existing = await getOpenShift();
    if (existing != null) {
      throw Exception('Sudah ada shift terbuka. Tutup dulu sebelum buka baru.');
    }
    return db.insert('shifts', {
      'user_id': userId,
      'opened_at': DateTime.now().toIso8601String(),
      'opening_cash': openingCash,
      'status': 'open',
      'notes': notes,
    });
  }

  Future<ShiftStats> getStats(int shiftId) async {
    final db = await _db;
    final orders = await db.query(
      'orders',
      where: 'shift_id = ? AND status = ?',
      whereArgs: [shiftId, 'paid'],
    );
    var total = 0.0;
    var cash = 0.0;
    var qris = 0.0;
    var card = 0.0;
    for (final row in orders) {
      final t = (row['total'] as num).toDouble();
      total += t;
      switch (row['payment_method'] as String) {
        case 'cash':
          cash += t;
          break;
        case 'qris':
          qris += t;
          break;
        case 'card':
          card += t;
          break;
      }
    }
    return ShiftStats(
      transactionCount: orders.length,
      totalSales: total,
      cashSales: cash,
      qrisSales: qris,
      cardSales: card,
    );
  }

  Future<Shift> closeShift({
    required int shiftId,
    required double closingCash,
    String notes = '',
  }) async {
    final db = await _db;
    final shift = await getById(shiftId);
    if (shift == null) throw Exception('Shift tidak ditemukan.');
    if (!shift.isOpen) throw Exception('Shift sudah ditutup.');

    final stats = await getStats(shiftId);
    final db2 = await _db;
    final expResult = await db2.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE shift_id = ?',
      [shiftId],
    );
    final expenseTotal = (expResult.first['total'] as num?)?.toDouble() ?? 0;
    final expected = shift.openingCash + stats.cashSales - expenseTotal;
    final difference = closingCash - expected;

    await db.update(
      'shifts',
      {
        'closed_at': DateTime.now().toIso8601String(),
        'closing_cash': closingCash,
        'expected_cash': expected,
        'difference': difference,
        'status': 'closed',
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );
    return (await getById(shiftId))!;
  }

  Future<List<Shift>> getHistory({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      'shifts',
      orderBy: 'opened_at DESC',
      limit: limit,
    );
    return rows.map(Shift.fromMap).toList();
  }
}
