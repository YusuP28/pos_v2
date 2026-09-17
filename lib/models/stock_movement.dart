class StockMovement {
  final int? id;
  final int productId;
  final int userId;
  final double quantity;
  final String type; // 'in' | 'out'
  final String notes;
  final String createdAt;

  const StockMovement({
    this.id,
    required this.productId,
    required this.userId,
    required this.quantity,
    this.type = 'in',
    this.notes = '',
    required this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, Object?> map) => StockMovement(
        id: map['id'] as int?,
        productId: map['product_id'] as int,
        userId: map['user_id'] as int,
        quantity: (map['quantity'] as num).toDouble(),
        type: (map['type'] as String?) ?? 'in',
        notes: (map['notes'] as String?) ?? '',
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'user_id': userId,
        'quantity': quantity,
        'type': type,
        'notes': notes,
        'created_at': createdAt,
      };
}
