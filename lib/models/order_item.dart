class OrderItem {
  final int? id;
  final int? orderId;
  final int? productId;
  final String productName;
  final double price;
  final double quantity;
  final double subtotal;

  const OrderItem({
    this.id,
    this.orderId,
    this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromMap(Map<String, Object?> map) => OrderItem(
        id: map['id'] as int?,
        orderId: map['order_id'] as int?,
        productId: map['product_id'] as int?,
        productName: map['product_name'] as String,
        price: (map['price'] as num).toDouble(),
        quantity: (map['quantity'] as num).toDouble(),
        subtotal: (map['subtotal'] as num).toDouble(),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        if (orderId != null) 'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}
