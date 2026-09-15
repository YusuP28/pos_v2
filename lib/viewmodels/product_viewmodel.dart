import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductViewModel extends ChangeNotifier {
  List<Product> _items = [];
  bool _loading = false;
  String _query = '';

  List<Product> get items => _items;
  bool get loading => _loading;
  String get query => _query;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await ProductRepository.instance.getAll(query: _query);
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String q) async {
    _query = q;
    _items = await ProductRepository.instance.getAll(query: q);
    notifyListeners();
  }

  Future<Product?> findByBarcode(String code) async {
    return ProductRepository.instance.findByBarcode(code);
  }

  Future<void> add(Product p) async {
    await ProductRepository.instance.insert(p);
    await load();
  }

  Future<void> edit(Product p) async {
    await ProductRepository.instance.update(p);
    await load();
  }

  Future<void> remove(int id) async {
    await ProductRepository.instance.softDelete(id);
    await load();
  }
}
