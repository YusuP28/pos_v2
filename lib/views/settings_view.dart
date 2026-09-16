import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/backup_service.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_toast.dart';

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
