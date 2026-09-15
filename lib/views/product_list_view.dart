import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/product_viewmodel.dart';
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
    Future.microtask(() => context.read<ProductViewModel>().load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormView()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: vm.search,
              decoration: const InputDecoration(
                hintText: 'Cari nama / SKU / barcode...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.items.isEmpty
                    ? const Center(child: Text('Belum ada produk.'))
                    : ListView.separated(
                        itemCount: vm.items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = vm.items[i];
                          return ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(p.name),
                            subtitle: Text(
                              '${p.sku.isEmpty ? "-" : p.sku} • stok ${p.stock.toStringAsFixed(0)} ${p.unit}',
                            ),
                            trailing: Text(
                              Currency.format(p.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductFormView(existing: p),
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
                                      child: const Text('Nonaktifkan'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && p.id != null) {
                                await vm.remove(p.id!);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
