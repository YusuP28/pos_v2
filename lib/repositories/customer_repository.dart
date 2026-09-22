import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../models/customer.dart';

class CustomerRepository {
  CustomerRepository._();
  static final CustomerRepository instance = CustomerRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<List<Customer>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'customers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<Customer?> getByPhone(String phone) async {
    final db = await _db;
    final rows = await db.query(
      'customers',
      where: 'phone = ? AND is_active = ?',
      whereArgs: [phone, 1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<List<Customer>> search(String query) async {
    final db = await _db;
    final rows = await db.query(
      'customers',
      where: 'is_active = ? AND name LIKE ?',
      whereArgs: [1, '%\$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> create({
    required String name,
    String phone = '',
    String email = '',
    String address = '',
    String notes = '',
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    return db.insert('customers', {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'points': 0,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> update(Customer customer) async {
    final db = await _db;
    await db.update(
      'customers',
      {
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
        'notes': customer.notes,
        'is_active': customer.isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> toggleActive(int id, bool isActive) async {
    final db = await _db;
    await db.update(
      'customers',
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addPoints(int customerId, int pointsToAdd) async {
    final db = await _db;
    final current = await getById(customerId);
    if (current == null) throw Exception('Customer not found');
    final newPoints = current.points + pointsToAdd;
    await db.update(
      'customers',
      {
        'points': newPoints,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }
}
