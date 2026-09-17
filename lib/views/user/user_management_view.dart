import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/app_appbar.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_toast.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<UserViewModel>().load());
  }

  Future<void> _openForm({User? existing}) async {
    final username = TextEditingController(text: existing?.username ?? '');
    final fullName = TextEditingController(text: existing?.fullName ?? '');
    final password = TextEditingController();
    String role = existing?.role ?? 'kasir';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            existing == null ? 'Tambah User' : 'Edit User',
            style: const TextStyle(fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: username,
                  enabled: existing == null,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fullName,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: existing == null
                        ? 'Password'
                        : 'Password baru (kosong = tidak ganti)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  ],
                  onChanged: (v) => setLocal(() => role = v ?? 'kasir'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(fontSize: 12)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'username': username.text.trim(),
                'full_name': fullName.text.trim(),
                'password': password.text,
                'role': role,
              }),
              child: const Text('Simpan', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    final vm = context.read<UserViewModel>();
    try {
      if (existing == null) {
        if (result['username'].isEmpty ||
            result['password'].isEmpty ||
            result['full_name'].isEmpty) {
          if (!mounted) return;
          await AppDialog.error(context, 'Semua field wajib diisi.',
              title: 'Data Tidak Lengkap');
          return;
        }
        await vm.add(
          username: result['username'],
          password: result['password'],
          fullName: result['full_name'],
          role: result['role'],
        );
        if (!mounted) return;
        AppToast.show(context, 'User ditambahkan.');
      } else {
        await vm.updateUser(
          id: existing.id!,
          fullName: result['full_name'],
          role: result['role'],
          newPassword: result['password'].isEmpty ? null : result['password'],
        );
        if (!mounted) return;
        AppToast.show(context, 'User diperbarui.');
      }
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, '$e', title: 'Gagal');
    }
  }

  Future<void> _delete(User u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User?', style: TextStyle(fontSize: 16)),
        content: Text('User "${u.username}" akan dihapus permanen.',
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

    final currentUserId = context.read<AuthViewModel>().currentUser?.id ?? -1;
    try {
      await context
          .read<UserViewModel>()
          .delete(u.id!, currentUserId: currentUserId);
      if (!mounted) return;
      AppToast.show(context, 'User dihapus.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, '$e', title: 'Tidak Bisa Dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();
    final currentUserId = context.watch<AuthViewModel>().currentUser?.id;
    return Scaffold(
      appBar: AppAppBar(
        title: 'Manajemen User',
        subtitle: 'Kasir & Admin',
        actions: [
          IconButton(
            tooltip: 'Tambah User',
            icon: const Icon(Icons.person_add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : vm.items.isEmpty
                  ? const Center(child: Text('Belum ada user.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: vm.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = vm.items[i];
                        final isMe = u.id == currentUserId;
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: u.isAdmin
                                ? Colors.deepPurple.shade100
                                : Colors.grey.shade200,
                            child: Icon(
                              u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                              size: 14,
                            ),
                          ),
                          title: Text(u.username,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            '${u.fullName}  •  ${u.role.toUpperCase()}${isMe ? "  •  (Anda)" : ""}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                onPressed: () => _openForm(existing: u),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline, size: 16),
                                onPressed: isMe ? null : () => _delete(u),
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
