import 'package:flutter/material.dart';

import '../../core/database/db_helper.dart';
import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';
import '../../widgets/app_appbar.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_toast.dart';

class CustomerListView extends StatefulWidget {
  const CustomerListView({super.key});

  @override
  State<CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends State<CustomerListView> {
  List<Customer> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _customers = await CustomerRepository.instance.getAll();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _addCustomer() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telepon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      await AppDialog.error(context, 'Nama wajib diisi.');
      return;
    }

    try {
      await CustomerRepository.instance.create(
        name: name,
        phone: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
      );
      await _load();
      await AppToast.show(context, 'Pelanggan ditambahkan.');
    } catch (e) {
      await AppDialog.error(context, 'Gagal: \$e');
    }
  }

  Future<void> _editCustomer(Customer c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone);
    final emailCtrl = TextEditingController(text: c.email);
    final addressCtrl = TextEditingController(text: c.address);
    final notesCtrl = TextEditingController(text: c.notes);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telepon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final updated = Customer(
      id: c.id,
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
      points: c.points,
      isActive: c.isActive,
      createdAt: c.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    try {
      await CustomerRepository.instance.update(updated);
      await _load();
      await AppToast.show(context, 'Pelanggan diperbarui.');
    } catch (e) {
      await AppDialog.error(context, 'Gagal: \$e');
    }
  }

  Future<void> _toggleActive(Customer c) async {
    final isActive = !c.isActive;
    await CustomerRepository.instance.toggleActive(c.id!, isActive);
    await _load();
    await AppToast.show(
      context,
      isActive ? 'Pelanggan diaktifkan.' : 'Pelanggan dinonaktifkan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Pelanggan',
        actions: [
          IconButton(
            tooltip: 'Tambah',
            icon: const Icon(Icons.person_add),
            onPressed: _addCustomer,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _customers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = _customers[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    child: Text(c.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(c.name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '\${c.phone.isEmpty ? '-' : c.phone}  \u2022  \${c.points} pts',
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editCustomer(c),
                      ),
                      IconButton(
                        icon: Icon(
                          c.isActive ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => _toggleActive(c),
                      ),
                    ],
                  ),
                  onTap: () => _editCustomer(c),
                );
              },
            ),
    );
  }
}
