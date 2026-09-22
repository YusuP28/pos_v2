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
  double get totalDiscount =>
      _items.fold<double>(0, (sum, it) => sum + it.discountAmount);
  double get total => subtotal - totalDiscount;

  double quantityOf(Product product) {
    final idx = _items.indexWhere((it) => it.product.id == product.id);
    if (idx < 0) return 0;
    return _items[idx].quantity;
  }

  bool canIncrease(Product product) {
    return quantityOf(product) < product.stock;
  }

  void add(Product product) {
    if (!canIncrease(product)) return;
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

  void setDiscount(Product product, DiscountType type, double value) {
    final idx = _items.indexWhere((it) => it.product.id == product.id);
    if (idx < 0) return;
    _items[idx].discountType = type;
    _items[idx].discountValue = value;
    notifyListeners();
  }

  void remove(Product product) {
    _items.removeWhere((it) => it.product.id == product.id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
