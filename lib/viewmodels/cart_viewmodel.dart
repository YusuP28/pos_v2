import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemCount =>
      _items.fold<int>(0, (sum, it) => sum + it.quantity.toInt());
  double get subtotal =>
      _items.fold<double>(0, (sum, it) => sum + it.subtotal);
  double get total => subtotal;

  void add(Product product) {
    final idx = _items.indexWhere((it) => it.product.id == product.id);
    if (idx >= 0) {
      _items[idx].quantity += 1;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void decrease(Product product) {
    final idx = _items.indexWhere((it) => it.product.id == product.id);
    if (idx < 0) return;
    if (_items[idx].quantity > 1) {
      _items[idx].quantity -= 1;
    } else {
      _items.removeAt(idx);
    }
    notifyListeners();
  }

  void remove(Product product) {
    _items.removeWhere((it) => it.product.id == product.id);
    notifyListeners();
  }

  void setQuantity(Product product, double qty) {
    final idx = _items.indexWhere((it) => it.product.id == product.id);
    if (idx < 0) return;
    if (qty <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx].quantity = qty;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
