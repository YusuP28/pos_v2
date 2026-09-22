class Order {
  final int? id;
  final String invoiceNumber;
  final int userId;
  final int? shiftId;
  final int? customerId;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final double paidAmount;
  final double changeAmount;
  final String status;
  final String createdAt;

  const Order({
    this.id,
    required this.invoiceNumber,
    required this.userId,
    this.shiftId,
    this.customerId,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    required this.paymentMethod,
    required this.paidAmount,
    required this.changeAmount,
    this.status = 'paid',
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, Object?> map) => Order(
        id: map['id'] as int?,
        invoiceNumber: map['invoice_number'] as String,
        userId: map['user_id'] as int,
        shiftId: map['shift_id'] as int?,
        customerId: map['customer_id'] as int?,
        subtotal: (map['subtotal'] as num).toDouble(),
        discount: (map['discount'] as num).toDouble(),
        tax: (map['tax'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        paymentMethod: map['payment_method'] as String,
        paidAmount: (map['paid_amount'] as num).toDouble(),
        changeAmount: (map['change_amount'] as num).toDouble(),
        status: map['status'] as String,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'invoice_number': invoiceNumber,
        'user_id': userId,
        'shift_id': shiftId,
        'customer_id': customerId,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
        'change_amount': changeAmount,
        'status': status,
        'created_at': createdAt,
      };
}
