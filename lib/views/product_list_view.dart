import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/product.dart';
import '../viewmodels/category_viewmodel.dart';
import '../repositories/stock_repository.dart';
import '../viewmodels/product_viewmodel.dart';
import '../widgets/app_appbar.dart';
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    return Scaffold(
      appBar: AppAppBar(
        title: 'Produk',
        subtitle: 'Kelola produk',
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormView()),
        ),
        child: const Icon(Icons.add, size: 18),
      ),
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
                                    child: InkWell(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductFormView(existing: p),
                                        ),
                                      ),
                                      onLongPress: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Hapus produk?'),
                                            content: Text(
                                              'Produk "${p.name}" akan dinonaktifkan.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Batal'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text(
                                                    'Nonaktifkan'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true && p.id != null) {
                                          await vm.remove(p.id!);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.inventory_2_outlined,
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'SKU: ${p.sku.isEmpty ? "-" : p.sku}',
                                              style: const TextStyle(
                                                  fontSize: 11),
                                            ),
                                            Text(
                                              'Stok: ${p.stock.toStringAsFixed(0)} ${p.unit}',
                                              style: const TextStyle(
                                                  fontSize: 11),
                                            ),
                                            const Spacer(),
                                            Text(
                                              Currency.format(p.price),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
