import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../viewmodels/category_viewmodel.dart';

class CategoryListView extends StatefulWidget {
  const CategoryListView({super.key});

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CategoryViewModel>().load());
  }

  Future<void> _openForm({Category? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final vm = context.read<CategoryViewModel>();
    if (existing == null) {
      await vm.add(result);
    } else {
      await vm.edit(Category(id: existing.id, name: result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.items.isEmpty
              ? const Center(child: Text('Belum ada kategori.'))
              : ListView.separated(
                  itemCount: vm.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = vm.items[i];
                    return ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(c.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openForm(existing: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus kategori?'),
                                  content: Text(
                                    'Kategori "${c.name}" akan dihapus.',
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
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && c.id != null) {
                                await vm.remove(c.id!);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
