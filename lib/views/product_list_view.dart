import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../models/product.dart';
import '../core/services/printer_service.dart';
import '../repositories/stock_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/printer_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_toast.dart';
import 'product_form_view.dart';

class ProductListView extends StatefulWidget {
  const ProductListView({super.key});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductViewModel>().load();
      context.read<CategoryViewModel>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addStock(Product p) async {
    final qty = TextEditingController();
    final notes = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Stok: ${p.name}',
            style: const TextStyle(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stok saat ini: ${p.stock.toStringAsFixed(0)} ${p.unit}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: qty,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah masuk',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notes,
              decoration: const InputDecoration(
                labelText: 'Catatan (mis. supplier)',
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
            onPressed: () => Navigator.pop(ctx, {
              'qty': qty.text.trim(),
              'notes': notes.text.trim(),
            }),
            child: const Text('Tambah', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (result == null) return;

    final jumlah = double.tryParse(result['qty'] ?? '') ?? 0;
    if (jumlah <= 0) {
      if (!mounted) return;
      AppToast.show(context, 'Jumlah tidak valid.', success: false);
      return;
    }

    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId == null) return;

    try {
      await StockRepository.instance.addStock(
        productId: p.id!,
        userId: userId,
        quantity: jumlah,
        notes: result['notes'] ?? '',
      );
      if (!mounted) return;
      AppToast.show(context, 'Stok ditambah +${jumlah.toStringAsFixed(0)}.');
      await context.read<ProductViewModel>().load();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Gagal: $e', success: false);
    }
  }

  Future<void> _printLabel(Product p) async {
    // Cek printer
    final printer = context.read<PrinterViewModel>();
    if (!printer.isConnected) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        'Printer belum terhubung. Hubungkan dulu di Pengaturan Printer.',
        title: 'Printer Belum Terhubung',
      );
      return;
    }

    // Cek barcode ada
    if (p.barcode.isEmpty) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        'Produk "${p.name}" belum punya barcode.\n\nEdit produk dulu untuk menambah barcode.',
        title: 'Barcode Kosong',
      );
      return;
    }

    // Dialog pilih jumlah label
    final qtyC = TextEditingController(text: '1');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cetak Label', style: TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produk: ${p.name}',
                style: const TextStyle(fontSize: 12)),
            Text('Barcode: ${p.barcode}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: qtyC,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah label',
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
            onPressed: () => Navigator.pop(ctx, qtyC.text.trim()),
            child: const Text('Cetak', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (result == null) return;
    final qty = int.tryParse(result) ?? 1;
    if (qty <= 0) return;

    try {
      final ok = await PrinterService.instance.printLabel(
        productName: p.name,
        barcode: p.barcode,
        price: p.price,
        qty: qty,
        paper80mm: printer.paper80mm,
      );
      if (!mounted) return;
      if (ok) {
        AppToast.show(context, 'Label dikirim ($qty).');
      } else {
        await AppDialog.error(context, 'Gagal cetak. Cek printer.',
            title: 'Gagal');
      }
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, 'Gagal: $e', title: 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    final isAdmin =
        context.watch<AuthViewModel>().currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppAppBar(title: 'Produk', subtitle: 'Kelola produk'),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              mini: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormView()),
              ),
              child: const Icon(Icons.add, size: 18),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: TextField(
                  controller: _search,
                  onChanged: vm.search,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama / SKU / barcode...',
                    hintStyle: TextStyle(fontSize: 12),
                    prefixIcon: Icon(Icons.search, size: 18),
                    prefixIconConstraints:
                        BoxConstraints(minWidth: 32, minHeight: 32),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              Expanded(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.items.isEmpty
                        ? const Center(child: Text('Belum ada produk.'))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = (constraints.maxWidth / 155)
                                  .floor()
                                  .clamp(2, 10);
                              return GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 4, 8, 80),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  childAspectRatio: 1.4,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                ),
                                itemCount: vm.items.length,
                                itemBuilder: (_, i) {
                                  final p = vm.items[i];
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: Stack(
                                      children: [
                                        InkWell(
                                          onTap: isAdmin
                                              ? () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ProductFormView(
                                                              existing: p),
                                                    ),
                                                  )
                                              : null,
                                          onLongPress: () async {
                                            // Menu pilihan
                                            final action =
                                                await showModalBottomSheet<String>(
                                              context: context,
                                              showDragHandle: true,
                                              builder: (ctx) => SafeArea(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ListTile(
                                                      leading: const Icon(
                                                          Icons.qr_code_2,
                                                          size: 20),
                                                      title: const Text(
                                                          'Cetak Label',
                                                          style: TextStyle(
                                                              fontSize: 13)),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                              ctx, 'label'),
                                                    ),
                                                    if (isAdmin)
                                                      ListTile(
                                                        leading: const Icon(
                                                            Icons.edit_outlined,
                                                            size: 20),
                                                        title: const Text(
                                                            'Edit Produk',
                                                            style: TextStyle(
                                                                fontSize: 13)),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                                ctx, 'edit'),
                                                      ),
                                                    if (isAdmin)
                                                      ListTile(
                                                        leading: const Icon(
                                                            Icons.delete_outline,
                                                            size: 20,
                                                            color: Colors.red),
                                                        title: const Text(
                                                            'Nonaktifkan',
                                                            style: TextStyle(
                                                                fontSize: 13,
                                                                color:
                                                                    Colors.red)),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                                ctx, 'delete'),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );

                                            if (!mounted) return;
                                            if (action == 'label') {
                                              await _printLabel(p);
                                            } else if (action == 'edit') {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ProductFormView(
                                                          existing: p),
                                                ),
                                              );
                                              await vm.load();
                                            } else if (action == 'delete') {
                                              final ok =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Hapus produk?'),
                                                  content: Text(
                                                    'Produk "${p.name}" akan dinonaktifkan.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, false),
                                                      child: const Text(
                                                          'Batal'),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                      child: const Text(
                                                          'Nonaktifkan'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true &&
                                                  p.id != null) {
                                                await vm.remove(p.id!);
                                              }
                                            }
                                          },
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .inventory_2_outlined,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        p.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 24),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'SKU: ${p.sku.isEmpty ? "-" : p.sku}',
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                                Text(
                                                  'Stok: ${p.stock.toStringAsFixed(0)} ${p.unit}',
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  Currency.format(p.price),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Tombol +Stok (selalu muncul — admin & kasir)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Material(
                                            color: Colors.green
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () => _addStock(p),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
