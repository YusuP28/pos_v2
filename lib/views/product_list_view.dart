import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/category_viewmodel.dart';
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _search,
                  onChanged: vm.search,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama / SKU / barcode...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.items.isEmpty
                        ? const Center(child: Text('Belum ada produk.'))
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 100),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              childAspectRatio: 1.6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
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
                                            child: const Text('Nonaktifkan'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true && p.id != null) {
                                      await vm.remove(p.id!);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                p.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'SKU: ${p.sku.isEmpty ? "-" : p.sku}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          'Stok: ${p.stock.toStringAsFixed(0)} ${p.unit}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const Spacer(),
                                        Text(
                                          Currency.format(p.price),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
