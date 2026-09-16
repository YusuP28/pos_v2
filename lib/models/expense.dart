class Expense {
  final int? id;
  final int? shiftId;
  final int userId;
  final double amount;
  final String category;
  final String notes;
  final String createdAt;

  const Expense({
    this.id,
    this.shiftId,
    required this.userId,
    required this.amount,
    this.category = 'Lain',
    this.notes = '',
    required this.createdAt,
  });

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int?,
        shiftId: map['shift_id'] as int?,
        userId: map['user_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        category: (map['category'] as String?) ?? 'Lain',
        notes: (map['notes'] as String?) ?? '',
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'shift_id': shiftId,
        'user_id': userId,
        'amount': amount,
        'category': category,
        'notes': notes,
        'created_at': createdAt,
      };
}
