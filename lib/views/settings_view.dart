import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../core/services/auth_service.dart';
import '../core/services/export_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../core/services/backup_service.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_toast.dart';
import 'about_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  Map<String, dynamic>? _info;
  List<BackupFile> _backups = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final info = await BackupService.instance.getInfo();
    final backups = await BackupService.instance.listBackups();
    if (!mounted) return;
    setState(() {
      _info = info;
      _backups = backups;
      _loading = false;
    });
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    try {
      final path = await BackupService.instance.backupNow();
      if (!mounted) return;
      AppToast.show(
        context,
        'Backup berhasil: ${path.split("/").last}',
        duration: const Duration(seconds: 3),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, 'Gagal backup: $e', title: 'Gagal');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(BackupFile file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup?', style: TextStyle(fontSize: 16)),
        content: Text(
          'Data saat ini akan DITIMPA oleh:\n\n'
          '${file.name}\n'
          'Ukuran: ${file.sizeLabel}\n'
          'Tanggal: ${file.modified.toString().substring(0, 19)}\n\n'
          'Data yang ada sekarang akan disimpan sebagai file safety '
          'sebelum ditimpa. Aplikasi akan ditutup setelah restore — '
          'buka ulang manual.',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('RESTORE', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await BackupService.instance.restoreFrom(file.path);
      if (!mounted) return;
      await AppDialog.info(
        context,
        'Restore berhasil.\\n\\nSilakan tutup aplikasi dan buka ulang '
        'untuk melihat data yang dipulihkan.',
        title: 'Restore Selesai',
      );
      if (!mounted) return;
      // Keluar dari app supaya user buka ulang
      SystemNavigator.pop();
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, 'Gagal restore: $e', title: 'Gagal');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteBackup(BackupFile file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Backup?', style: TextStyle(fontSize: 16)),
        content: Text('File ${file.name} akan dihapus permanen.',
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
    await BackupService.instance.deleteBackup(file.path);
    await _load();
    if (mounted) AppToast.show(context, 'Backup dihapus.');
  }

  Future<void> _openPinDialog() async {
    final hasPin = await AuthService.instance.hasPin();
    final pin = TextEditingController();
    final confirm = TextEditingController();

    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasPin ? 'Ganti PIN' : 'Atur PIN',
            style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PIN 4-digit untuk buka aplikasi.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirm,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi PIN',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
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
              'pin': pin.text,
              'confirm': confirm.text,
            }),
            child: const Text('Simpan', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (result == null) return;

    final p = result['pin'] ?? '';
    final c = result['confirm'] ?? '';
    if (p.length != 4 || !RegExp(r'^\d{4}$').hasMatch(p)) {
      if (!mounted) return;
      await AppDialog.error(context, 'PIN harus 4 digit angka.',
          title: 'PIN Tidak Valid');
      return;
    }
    if (p != c) {
      if (!mounted) return;
      await AppDialog.error(context, 'PIN dan konfirmasi tidak sama.',
          title: 'Tidak Cocok');
      return;
    }
    await AuthService.instance.setPin(p);
    if (!mounted) return;
    AppToast.show(context, hasPin ? 'PIN diganti.' : 'PIN diatur.');
    setState(() {});
  }

  Future<void> _removePin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus PIN?', style: TextStyle(fontSize: 16)),
        content: const Text(
          'Setelah hapus, aplikasi langsung masuk tanpa PIN.',
          style: TextStyle(fontSize: 12),
        ),
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
    await AuthService.instance.removePin();
    if (!mounted) return;
    AppToast.show(context, 'PIN dihapus.');
    setState(() {});
  }

  Future<void> _openPinAdminDialog() async {
    final hasPin = await AuthService.instance.hasPinAdmin();
    final pin = TextEditingController();
    final confirm = TextEditingController();

    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasPin ? 'Ganti PIN Admin' : 'Atur PIN Admin',
            style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PIN Admin 6-digit. Hanya admin yang tahu.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'PIN Admin',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirm,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi PIN Admin',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
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
              'pin': pin.text,
              'confirm': confirm.text,
            }),
            child: const Text('Simpan', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (result == null) return;

    final p = result['pin'] ?? '';
    final c = result['confirm'] ?? '';
    if (p.length != 6 || !RegExp(r'^\d{6}$').hasMatch(p)) {
      if (!mounted) return;
      await AppDialog.error(context, 'PIN Admin harus 6 digit angka.',
          title: 'PIN Tidak Valid');
      return;
    }
    if (p != c) {
      if (!mounted) return;
      await AppDialog.error(context, 'PIN dan konfirmasi tidak sama.',
          title: 'Tidak Cocok');
      return;
    }
    await AuthService.instance.setPinAdmin(p);
    if (!mounted) return;
    AppToast.show(context, hasPin ? 'PIN Admin diganti.' : 'PIN Admin diatur.');
    setState(() {});
  }

  Future<void> _removePinAdmin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus PIN Admin?', style: TextStyle(fontSize: 16)),
        content: const Text(
          'Setelah hapus, kasir tidak bisa akses menu admin sama sekali.',
          style: TextStyle(fontSize: 12),
        ),
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
    await AuthService.instance.removePinAdmin();
    if (!mounted) return;
    AppToast.show(context, 'PIN Admin dihapus.');
    setState(() {});
  }

  Future<void> _exportCSV(String jenis) async {
    setState(() => _busy = true);
    try {
      String path;
      switch (jenis) {
        case 'transaksi':
          path = await ExportService.instance.exportOrders();
          break;
        case 'produk':
          path = await ExportService.instance.exportProducts();
          break;
        case 'detail':
          path = await ExportService.instance.exportOrderItems();
          break;
        default:
          throw Exception('Jenis export tidak dikenal.');
      }
      if (!mounted) return;
      AppToast.show(
        context,
        'Export berhasil: ${path.split("/").last}',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, 'Gagal export: $e', title: 'Gagal');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Pengaturan',
        subtitle: 'Info aplikasi, backup & restore',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Keamanan — PIN
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('Keamanan',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: FutureBuilder<bool>(
                          future: AuthService.instance.hasPin(),
                          builder: (ctx, snap) {
                            final hasPin = snap.data ?? false;
                            return Row(
                              children: [
                                Icon(
                                  hasPin ? Icons.lock : Icons.lock_open,
                                  size: 20,
                                  color: hasPin
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasPin
                                            ? 'PIN aktif'
                                            : 'PIN belum diatur',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        hasPin
                                            ? 'Aplikasi minta PIN saat dibuka'
                                            : 'Aplikasi langsung masuk tanpa PIN',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _openPinDialog,
                                  child: Text(
                                    hasPin ? 'Ganti' : 'Atur',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                if (hasPin)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16),
                                    onPressed: _removePin,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // PIN Admin — admin only
                    if (context.watch<AuthViewModel>().currentUser?.isAdmin ?? false) ...[
                      const SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: FutureBuilder<bool>(
                            future: AuthService.instance.hasPinAdmin(),
                            builder: (ctx, snap) {
                              final hasPin = snap.data ?? false;
                              return Row(
                                children: [
                                  Icon(
                                    hasPin
                                        ? Icons.admin_panel_settings
                                        : Icons.shield_outlined,
                                    size: 20,
                                    color: hasPin
                                        ? Colors.deepPurple
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hasPin
                                              ? 'PIN Admin aktif'
                                              : 'PIN Admin belum diatur',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          hasPin
                                              ? 'Kasir butuh PIN ini untuk buka menu admin'
                                              : 'Kasir tidak bisa akses menu admin',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _openPinAdminDialog,
                                    child: Text(
                                      hasPin ? 'Ganti' : 'Atur',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  if (hasPin)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16),
                                      onPressed: _removePinAdmin,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Info aplikasi
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('Info Aplikasi',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _kv('Versi', '0.1.0'),
                            _kv('Jumlah produk aktif',
                                '${_info?['products'] ?? 0}'),
                            _kv('Jumlah transaksi',
                                '${_info?['orders'] ?? 0}'),
                            _kv('Jumlah shift',
                                '${_info?['shifts'] ?? 0}'),
                            _kv('Ukuran database',
                                _formatBytes(_info?['size'] ?? 0)),
                          ],
                        ),
                      ),
                    ),

                    // Tombol backup
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('Backup & Restore',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _backupNow,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_alt, size: 18),
                              label: Text(
                                  _busy ? 'MEMPROSES...' : 'BACKUP SEKARANG',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi file backup:',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            FutureBuilder<Directory>(
                              future: BackupService.instance.getBackupDir(),
                              builder: (ctx, snap) {
                                return Text(
                                  snap.data?.path ?? '...',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace'),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Bisa diakses via file manager di folder '
                              'Android/data/com.yusup.posv2/files/pos_v2_backup/',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Export CSV
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('Export Data (CSV)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'File CSV bisa dibuka di Excel / Google Sheets.',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            FutureBuilder<Directory>(
                              future: ExportService.instance.getExportDir(),
                              builder: (ctx, snap) {
                                return Text(
                                  snap.data?.path ?? '...',
                                  style: const TextStyle(
                                      fontSize: 10, fontFamily: 'monospace'),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: FilledButton.icon(
                                      onPressed: _busy
                                          ? null
                                          : () => _exportCSV('transaksi'),
                                      icon: const Icon(Icons.receipt_long,
                                          size: 16),
                                      label: const Text('TRANSAKSI',
                                          style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: FilledButton.icon(
                                      onPressed: _busy
                                          ? null
                                          : () => _exportCSV('detail'),
                                      icon: const Icon(Icons.list_alt,
                                          size: 16),
                                      label: const Text('DETAIL ITEM',
                                          style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: FilledButton.icon(
                                      onPressed: _busy
                                          ? null
                                          : () => _exportCSV('produk'),
                                      icon: const Icon(Icons.inventory_2,
                                          size: 16),
                                      label: const Text('PRODUK',
                                          style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Daftar backup
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          const Text('Daftar Backup',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${_backups.length} file',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_backups.isEmpty)
                      const Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Belum ada backup. Tap "BACKUP SEKARANG" untuk '
                            'membuat backup pertama.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._backups.map(
                        (b) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: const Icon(Icons.archive_outlined,
                                size: 20),
                            title: Text(b.name,
                                style: const TextStyle(fontSize: 12)),
                            subtitle: Text(
                              '${b.sizeLabel}  •  ${b.modified.toString().substring(0, 19)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Restore',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.restore, size: 18),
                                  onPressed:
                                      _busy ? null : () => _restore(b),
                                ),
                                IconButton(
                                  tooltip: 'Hapus',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  onPressed:
                                      _busy ? null : () => _deleteBackup(b),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Section Tentang Aplikasi
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.deepPurple),
                          SizedBox(width: 6),
                          Text('Tentang',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.info_outline, size: 20),
                        title: const Text('Tentang Aplikasi',
                            style: TextStyle(fontSize: 12)),
                        subtitle: const Text(
                          'Informasi aplikasi, developer, dan versi',
                          style: TextStyle(fontSize: 10),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AboutView()),
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

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatBytes(num bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}
