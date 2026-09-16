import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  List<Expense> _items = [];
  bool _loading = false;
  int? _shiftId;

  List<Expense> get items => _items;
  bool get loading => _loading;

  double get total => _items.fold<double>(0, (s, e) => s + e.amount);

  Future<void> loadByShift(int? shiftId) async {
    _shiftId = shiftId;
    _loading = true;
    notifyListeners();
    if (shiftId == null) {
      _items = [];
    } else {
      _items = await ExpenseRepository.instance.getByShift(shiftId);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add({
    required int userId,
    required double amount,
    required String category,
    required String notes,
  }) async {
    await ExpenseRepository.instance.insert(Expense(
      shiftId: _shiftId,
      userId: userId,
      amount: amount,
      category: category,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
    ));
    await loadByShift(_shiftId);
  }

  Future<void> remove(int id) async {
    await ExpenseRepository.instance.delete(id);
    await loadByShift(_shiftId);
  }
}
