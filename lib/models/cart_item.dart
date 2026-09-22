import 'product.dart';

enum DiscountType { none, percent, nominal }

class CartItem {
  final Product product;
  double quantity;
  DiscountType discountType;
  double discountValue; // % atau Rp

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discountType = DiscountType.none,
    this.discountValue = 0,
  });

  double get subtotal => product.price * quantity;

  double get discountAmount {
    switch (discountType) {
      case DiscountType.percent:
        return subtotal * (discountValue.clamp(0, 100) / 100);
      case DiscountType.nominal:
        return discountValue.clamp(0, subtotal);
      case DiscountType.none:
        return 0;
    }
  }

  double get total => subtotal - discountAmount;
}
