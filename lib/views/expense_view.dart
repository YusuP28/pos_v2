import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../viewmodels/shift_viewmodel.dart';
import '../repositories/expense_category_repository.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_toast.dart';

class ExpenseView extends StatefulWidget {
  const ExpenseView({super.key});

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  List<String> _categories = [];
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'Operasional';

  Future<void> _loadCategories() async {
    final list = await ExpenseCategoryRepository.instance.getAll();
    if (!mounted) return;
    setState(() {
      _categories = list;
      if (!_categories.contains(_category) && _categories.isNotEmpty) {
        _category = _categories.first;
      }
    });
  }

  Future<void> _manageCategories() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final categories = List<String>.from(_categories);
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.category_outlined, size: 20),
                SizedBox(width: 8),
                Text('Kelola Kategori', style: TextStyle(fontSize: 15)),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori default tidak bisa dihapus.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Belum ada kategori.',
                          style: TextStyle(fontSize: 12)),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final name = categories[i];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            title: Text(name,
                                style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () async {
                                try {
                                  await ExpenseCategoryRepository.instance
                                      .delete(name);
                                  await _loadCategories();
                                  if (!ctx.mounted) return;
                                  setLocal(() {});
                                  if (!mounted) return;
                                  AppToast.show(
                                      context, 'Kategori dihapus.');
                                } catch (e) {
                                  if (!mounted) return;
                                  AppToast.show(context, '$e',
                                      success: false);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final c = TextEditingController();
                        final result = await showDialog<String>(
                          context: ctx,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Tambah Kategori',
                                style: TextStyle(fontSize: 15)),
                            content: TextField(
                              controller: c,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: 'Nama kategori',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dctx),
                                child: const Text('Batal',
                                    style: TextStyle(fontSize: 12)),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dctx, c.text.trim()),
                                child: const Text('Simpan',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                        if (result == null || result.isEmpty) return;
                        try {
                          await ExpenseCategoryRepository.instance
                              .add(result);
                          await _loadCategories();
                          if (!ctx.mounted) return;
                          setLocal(() {});
                          if (!mounted) return;
                          AppToast.show(
                              context, 'Kategori "$result" ditambahkan.');
                        } catch (e) {
                          if (!mounted) return;
                          AppToast.show(context, 'Gagal: $e',
                              success: false);
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Kategori',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteCategory(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?', style: TextStyle(fontSize: 15)),
        content: Text('Kategori "$name" akan dihapus.',
            style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ExpenseCategoryRepository.instance.delete(name);
      await _loadCategories();
      if (!mounted) return;
      AppToast.show(context, 'Kategori dihapus.');
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '$e', success: false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final shiftId = context.read<ShiftViewModel>().current?.id;
      context.read<ExpenseViewModel>().loadByShift(shiftId);
      await _loadCategories();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      await AppDialog.error(context, 'Jumlah harus lebih dari 0.',
          title: 'Data Tidak Valid');
      return;
    }

    final shift = context.read<ShiftViewModel>();
    if (!shift.hasOpenShift) {
      await AppDialog.error(
        context,
        'Belum ada shift terbuka. Buka shift dulu di menu Shift Kas.',
        title: 'Shift Belum Dibuka',
      );
      return;
    }

    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId == null) return;

    try {
      await context.read<ExpenseViewModel>().add(
            userId: userId,
            amount: amount,
            category: _category,
            notes: _notes.text.trim(),
          );
      _amount.clear();
      _notes.clear();
      if (!mounted) return;
      AppToast.show(context, 'Pengeluaran dicatat.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, 'Gagal: $e', title: 'Gagal');
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengeluaran?', style: TextStyle(fontSize: 16)),
        content: const Text('Data pengeluaran akan dihapus.',
            style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<ExpenseViewModel>().remove(id);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final shift = context.watch<ShiftViewModel>();

    return Scaffold(
      appBar: AppAppBar(
        title: 'Pengeluaran Kas',
        subtitle: 'Catat belanja / biaya operasional',
        actions: [
          IconButton(
            tooltip: 'Kelola kategori',
            icon: const Icon(Icons.category_outlined),
            onPressed: _manageCategories,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Status shift
              if (!shift.hasOpenShift)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Shift belum dibuka. Buka shift dulu di menu Shift Kas.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Form input
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _amount,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah (Rp)',
                              labelStyle: TextStyle(fontSize: 12),
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _category,
                            isDense: true,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              labelStyle: TextStyle(fontSize: 12),
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _category = v ?? 'Operasional'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notes,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: shift.hasOpenShift ? _submit : null,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('CATAT PENGELUARAN',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),

              // Ringkasan total
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_down, size: 18),
                        const SizedBox(width: 6),
                        const Text('Total pengeluaran shift ini',
                            style: TextStyle(fontSize: 12)),
                        const Spacer(),
                        Text(
                          Currency.format(vm.total),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Daftar
              Expanded(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.items.isEmpty
                        ? const Center(
                            child: Text('Belum ada pengeluaran shift ini.',
                                style: TextStyle(fontSize: 12)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: vm.items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final e = vm.items[i];
                              final dt = e.createdAt
                                  .replaceFirst('T', ' ')
                                  .substring(0, 19);
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: const Icon(Icons.receipt, size: 18),
                                title: Text(
                                  '${e.category}  •  ${Currency.format(e.amount)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  e.notes.isEmpty
                                      ? dt
                                      : '$dt  •  ${e.notes}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16),
                                  onPressed: () => _delete(e.id!),
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
