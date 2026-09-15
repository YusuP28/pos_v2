import 'package:flutter/material.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  List<Category> _items = [];
  bool _loading = false;

  List<Category> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await CategoryRepository.instance.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(String name) async {
    await CategoryRepository.instance.insert(Category(name: name));
    await load();
  }

  Future<void> edit(Category c) async {
    await CategoryRepository.instance.update(c);
    await load();
  }

  Future<void> remove(int id) async {
    await CategoryRepository.instance.delete(id);
    await load();
  }
}
