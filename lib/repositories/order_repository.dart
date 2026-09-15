import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderRepository {
  OrderRepository._();
  static final OrderRepository instance = OrderRepository._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<String> _generateInvoice() async {
    final db = await _db;
    final now = DateTime.now();
    final datePart =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timePart =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final prefix = 'INV-$datePart-$timePart';
    final rows = await db.query(
      'orders',
      columns: ['invoice_number'],
      where: 'invoice_number LIKE ?',
      whereArgs: ['$prefix%'],
    );
    final seq = (rows.length + 1).toString().padLeft(3, '0');
    return '$prefix-$seq';
  }

  Future<int> createOrder({
    required int userId,
    required List<CartItem> items,
    required String paymentMethod,
    required double paidAmount,
  }) async {
    if (items.isEmpty) {
      throw Exception('Cart kosong.');
    }

    final db = await _db;
    final invoice = await _generateInvoice();
    final subtotal =
        items.fold<double>(0, (sum, it) => sum + it.subtotal);
    final total = subtotal;
    final change = paidAmount - total;
    final nowIso = DateTime.now().toIso8601String();

    return db.transaction<int>((txn) async {
      // Cek stok + kurangi
      for (final it in items) {
        final rows = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [it.product.id],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw Exception('Produk ${it.product.name} tidak ditemukan.');
        }
        final stock = (rows.first['stock'] as num).toDouble();
        if (stock < it.quantity) {
          throw Exception(
            'Stok ${it.product.name} tidak cukup (tersedia ${stock.toStringAsFixed(0)} ${it.product.unit}).',
          );
        }
      }

      final orderId = await txn.insert('orders', {
        'invoice_number': invoice,
        'user_id': userId,
        'shift_id': null,
        'subtotal': subtotal,
        'discount': 0,
        'tax': 0,
        'total': total,
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
        'change_amount': change,
        'status': 'paid',
        'created_at': nowIso,
      });

      for (final it in items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': it.product.id,
          'product_name': it.product.name,
          'price': it.product.price,
          'quantity': it.quantity,
          'subtotal': it.subtotal,
          'created_at': nowIso,
        });
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [it.quantity, it.product.id],
        );
      }

      return orderId;
    });
  }

  Future<Order?> getById(int orderId) async {
    final db = await _db;
    final rows =
        await db.query('orders', where: 'id = ?', whereArgs: [orderId], limit: 1);
    if (rows.isEmpty) return null;
    return Order.fromMap(rows.first);
  }

  Future<List<OrderItem>> getItems(int orderId) async {
    final db = await _db;
    final rows = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
    );
    return rows.map(OrderItem.fromMap).toList();
  }

  Future<List<Order>> getTodayOrders() async {
    final db = await _db;
    final now = DateTime.now();
    final start =
        DateTime(now.year, now.month, now.day).toIso8601String();
    final rows = await db.query(
      'orders',
      where: 'created_at >= ?',
      whereArgs: [start],
      orderBy: 'created_at DESC',
    );
    return rows.map(Order.fromMap).toList();
  }
}
