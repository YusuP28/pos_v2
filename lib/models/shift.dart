class Shift {
  final int? id;
  final int userId;
  final String openedAt;
  final String? closedAt;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? difference;
  final String status;
  final String notes;

  const Shift({
    this.id,
    required this.userId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.difference,
    this.status = 'open',
    this.notes = '',
  });

  bool get isOpen => status == 'open';

  factory Shift.fromMap(Map<String, Object?> map) => Shift(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        openedAt: map['opened_at'] as String,
        closedAt: map['closed_at'] as String?,
        openingCash: (map['opening_cash'] as num).toDouble(),
        closingCash: (map['closing_cash'] as num?)?.toDouble(),
        expectedCash: (map['expected_cash'] as num?)?.toDouble(),
        difference: (map['difference'] as num?)?.toDouble(),
        status: (map['status'] as String?) ?? 'open',
        notes: (map['notes'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'opened_at': openedAt,
        'closed_at': closedAt,
        'opening_cash': openingCash,
        'closing_cash': closingCash,
        'expected_cash': expectedCash,
        'difference': difference,
        'status': status,
        'notes': notes,
      };
}

class ShiftStats {
  final int transactionCount;
  final double totalSales;
  final double cashSales;
  final double qrisSales;
  final double cardSales;

  const ShiftStats({
    required this.transactionCount,
    required this.totalSales,
    required this.cashSales,
    required this.qrisSales,
    required this.cardSales,
  });
}
