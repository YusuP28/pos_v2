import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/db_helper.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  Future<Directory> getExportDir() async {
    // Simpan di folder Download (shared storage) supaya bisa diakses user
    final base = Directory('/storage/emulated/0/Download/pos_v2_export');
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    return base;
  }

  String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_'
        '${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }

  /// Escape field CSV — pakai separator ';'
  String _csv(String? v) {
    final s = (v ?? '').replaceAll('"', '""');
    if (s.contains(';') || s.contains('"') || s.contains('\n')) {
      return '"$s"';
    }
    return s;
  }

  Future<String> exportProducts() async {
    final db = await DbHelper.instance.database;
    final rows = await db.query('products', orderBy: 'name ASC');

    final buffer = StringBuffer();
    buffer.writeln('id;name;sku;barcode;category_id;price;cost_price;stock;unit;is_active');
    for (final r in rows) {
      buffer.writeln([
        _csv('${r['id']}'),
        _csv(r['name'] as String?),
        _csv(r['sku'] as String?),
        _csv(r['barcode'] as String?),
        _csv('${r['category_id']}'),
        _csv('${r['price']}'),
        _csv('${r['cost_price']}'),
        _csv('${r['stock']}'),
        _csv(r['unit'] as String?),
        _csv('${r['is_active']}'),
      ].join(';'));
    }

    final dir = await getExportDir();
    final file = File(p.join(dir.path, 'produk_${_stamp()}.csv'));
    // UTF-8 BOM agar Excel membaca UTF-8 dengan benar
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())];
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String> exportOrders({DateTime? start, DateTime? end}) async {
    final db = await DbHelper.instance.database;
    List<Map<String, Object?>> rows;
    if (start != null && end != null) {
      rows = await db.query(
        'orders',
        where: 'created_at >= ? AND created_at < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'created_at DESC',
      );
    } else {
      rows = await db.query('orders', orderBy: 'created_at DESC');
    }

    final buffer = StringBuffer();
    buffer.writeln('invoice;tanggal;user_id;shift_id;subtotal;discount;tax;total;'
        'payment_method;paid_amount;change_amount;status');

    for (final r in rows) {
      buffer.writeln([
        _csv(r['invoice_number'] as String?),
        _csv(r['created_at'] as String?),
        _csv('${r['user_id']}'),
        _csv('${r['shift_id']}'),
        _csv('${r['subtotal']}'),
        _csv('${r['discount']}'),
        _csv('${r['tax']}'),
        _csv('${r['total']}'),
        _csv(r['payment_method'] as String?),
        _csv('${r['paid_amount']}'),
        _csv('${r['change_amount']}'),
        _csv(r['status'] as String?),
      ].join(';'));
    }

    final dir = await getExportDir();
    final file = File(p.join(dir.path, 'transaksi_${_stamp()}.csv'));
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())];
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Export detail transaksi + item
  Future<String> exportOrderItems() async {
    final db = await DbHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT oi.id, oi.order_id, o.invoice_number, o.created_at,
             oi.product_name, oi.price, oi.quantity, oi.subtotal
      FROM order_items oi
      LEFT JOIN orders o ON o.id = oi.order_id
      ORDER BY o.created_at DESC, oi.id ASC
    ''');

    final buffer = StringBuffer();
    buffer.writeln('invoice;tanggal;product_name;price;quantity;subtotal');
    for (final r in rows) {
      buffer.writeln([
        _csv(r['invoice_number'] as String?),
        _csv(r['created_at'] as String?),
        _csv(r['product_name'] as String?),
        _csv('${r['price']}'),
        _csv('${r['quantity']}'),
        _csv('${r['subtotal']}'),
      ].join(';'));
    }

    final dir = await getExportDir();
    final file = File(p.join(dir.path, 'transaksi_detail_${_stamp()}.csv'));
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())];
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<int> getCount(String table) async {
    final db = await DbHelper.instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return (r.first['c'] as int?) ?? 0;
  }
}
