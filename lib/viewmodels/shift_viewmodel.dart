import 'package:flutter/material.dart';

import '../core/database/db_helper.dart';
import '../models/shift.dart';
import '../repositories/shift_repository.dart';

class ShiftViewModel extends ChangeNotifier {
  Shift? _current;
  ShiftStats? _stats;
  double _expenseTotal = 0;
  bool _loading = false;

  List<Shift> _history = [];
  bool _historyLoading = false;

  Shift? get current => _current;
  ShiftStats? get stats => _stats;
  double get expenseTotal => _expenseTotal;
  bool get loading => _loading;
  bool get hasOpenShift => _current != null;

  List<Shift> get history => _history;
  bool get historyLoading => _historyLoading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _current = await ShiftRepository.instance.getOpenShift();
    if (_current?.id != null) {
      _stats = await ShiftRepository.instance.getStats(_current!.id!);
      _expenseTotal = await _getExpenseTotal(_current!.id!);
    } else {
      _stats = null;
      _expenseTotal = 0;
    }
    _loading = false;
    notifyListeners();
  }

  Future<double> _getExpenseTotal(int shiftId) async {
    try {
      final db = await DbHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE shift_id = ?',
        [shiftId],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> open(double openingCash, {String notes = ''}) async {
    final user = _pendingUserId;
    if (user == null) throw Exception('User tidak dikenal.');
    await ShiftRepository.instance.openShift(
      userId: user,
      openingCash: openingCash,
      notes: notes,
    );
    await load();
  }

  int? _pendingUserId;
  set pendingUserId(int? v) => _pendingUserId = v;

  Future<Shift> close(double closingCash, {String notes = ''}) async {
    if (_current?.id == null) throw Exception('Tidak ada shift terbuka.');
    final closed = await ShiftRepository.instance.closeShift(
      shiftId: _current!.id!,
      closingCash: closingCash,
      notes: notes,
    );
    await load();
    return closed;
  }

  // ---- History ----

  Future<void> loadHistory({
    DateTime? start,
    DateTime? end,
    int limit = 100,
  }) async {
    _historyLoading = true;
    notifyListeners();
    try {
      final db = await DbHelper.instance.database;
      List<Map<String, Object?>> rows;
      if (start != null && end != null) {
        rows = await db.query(
          'shifts',
          where: 'opened_at >= ? AND opened_at < ?',
          whereArgs: [start.toIso8601String(), end.toIso8601String()],
          orderBy: 'opened_at DESC',
          limit: limit,
        );
      } else {
        rows = await db.query(
          'shifts',
          orderBy: 'opened_at DESC',
          limit: limit,
        );
      }
      _history = rows.map(Shift.fromMap).toList();
    } catch (_) {
      _history = [];
    }
    _historyLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getShiftDetail(int shiftId) async {
    final db = await DbHelper.instance.database;

    final stats = await ShiftRepository.instance.getStats(shiftId);

    final expResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE shift_id = ?',
      [shiftId],
    );
    final expenseTotal = (expResult.first['total'] as num?)?.toDouble() ?? 0;

    final expList = await db.query(
      'expenses',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'created_at ASC',
    );

    return {
      'stats': stats,
      'expenseTotal': expenseTotal,
      'expenses': expList,
    };
  }
}
