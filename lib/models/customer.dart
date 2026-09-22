import 'package:sqflite/sqflite.dart';

class Customer {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final int points;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.points = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        address: map['address'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        points: map['points'] as int? ?? 0,
        isActive: (map['is_active'] as int? ?? 1) == 1,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'points': points,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
