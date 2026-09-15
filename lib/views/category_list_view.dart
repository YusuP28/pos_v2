import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/app_appbar.dart';

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
        title: Text(
          existing == null ? 'Tambah Kategori' : 'Edit Kategori',
          style: const TextStyle(fontSize: 15),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan', style: TextStyle(fontSize: 12)),
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
      appBar: AppAppBar(
        title: 'Kategori',
        subtitle: 'Kelola kategori',
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, size: 18),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : vm.items.isEmpty
                  ? const Center(child: Text('Belum ada kategori.'))
                  : ListView.separated(
                      itemCount: vm.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = vm.items[i];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading:
                              const Icon(Icons.category_outlined, size: 18),
                          title: Text(c.name,
                              style: const TextStyle(fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                onPressed: () => _openForm(existing: c),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon:
                                    const Icon(Icons.delete_outline, size: 16),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hapus kategori?',
                                          style: TextStyle(fontSize: 15)),
                                      content: Text(
                                        'Kategori "${c.name}" akan dihapus.',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Batal',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Hapus',
                                              style: TextStyle(fontSize: 12)),
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
        ),
      ),
    );
  }
}
