import 'package:flutter/material.dart';

import '../../core/database/db_helper.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/currency.dart';
import '../../models/product.dart';
import '../../widgets/app_appbar.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_toast.dart';
import 'stock_movement_view.dart';

class StockReportView extends StatefulWidget {
  const StockReportView({super.key});

  @override
  State<StockReportView> createState() => _StockReportViewState();
}

class _StockReportViewState extends State<StockReportView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _threshold = 5;
  List<Product> _all = [];
  List<Product> _low = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _threshold = await SettingsService.instance.getLowStockThreshold();

    final db = await DbHelper.instance.database;
    final rows = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'stock ASC, name ASC',
    );
    final all = rows.map(Product.fromMap).toList();
    final low = all.where((p) => p.stock <= _threshold).toList();

    if (!mounted) return;
    setState(() {
      _all = all;
      _low = low;
      _loading = false;
    });
  }

  Future<void> _editThreshold() async {
    final c = TextEditingController(text: '$_threshold');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minimum Stok', style: TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Produk dengan stok ≤ angka ini akan ditandai low stock.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Minimum stok',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Simpan', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (result == null) return;
    final v = int.tryParse(result);
    if (v == null || v < 0) {
      if (!mounted) return;
      await AppDialog.error(context, 'Angka tidak valid.');
      return;
    }
    await SettingsService.instance.setLowStockThreshold(v);
    if (!mounted) return;
    AppToast.show(context, 'Minimum stok: $v');
    await _load();
  }

  void _openMovement(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockMovementView(product: p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Laporan Stok',
        subtitle: 'Minimum: $_threshold pcs',
        actions: [
          IconButton(
            tooltip: 'Ubah minimum stok',
            icon: const Icon(Icons.tune),
            onPressed: _editThreshold,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Low Stock (${_low.length})'),
            Tab(text: 'Semua (${_all.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildList(_low, emptyText: 'Semua stok aman.'),
                _buildList(_all, emptyText: 'Belum ada produk.'),
              ],
            ),
    );
  }

  Widget _buildList(List<Product> products, {required String emptyText}) {
    if (products.isEmpty) {
      return Center(child: Text(emptyText, style: const TextStyle(fontSize: 12)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = products[i];
        final isLow = p.stock <= _threshold;
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(
            isLow ? Icons.warning_amber : Icons.inventory_2_outlined,
            color: isLow ? Colors.orange : Colors.grey,
            size: 20,
          ),
          title: Text(p.name, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${p.sku.isEmpty ? "-" : p.sku}  •  ${Currency.format(p.price)}',
            style: const TextStyle(fontSize: 10),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.stock.toStringAsFixed(0)} ${p.unit}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLow ? Colors.orange.shade800 : Colors.black87,
                ),
              ),
              Text(
                'Tap untuk riwayat',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
            ],
          ),
          onTap: () => _openMovement(p),
        );
      },
    );
  }
}
