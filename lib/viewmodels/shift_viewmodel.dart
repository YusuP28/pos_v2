import 'package:flutter/material.dart';

import '../core/database/db_helper.dart';
import '../models/shift.dart';
import '../repositories/shift_repository.dart';

class ShiftViewModel extends ChangeNotifier {
  Shift? _current;
  ShiftStats? _stats;
  double _expenseTotal = 0;
  bool _loading = false;

  Shift? get current => _current;
  ShiftStats? get stats => _stats;
  double get expenseTotal => _expenseTotal;
  bool get loading => _loading;
  bool get hasOpenShift => _current != null;

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
}
