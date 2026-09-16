import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/bt_scanner_service.dart';
import '../viewmodels/printer_viewmodel.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';

class PrinterSettingsView extends StatefulWidget {
  const PrinterSettingsView({super.key});

  @override
  State<PrinterSettingsView> createState() => _PrinterSettingsViewState();
}

class _PrinterSettingsViewState extends State<PrinterSettingsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PrinterViewModel>().load());
  }

  Future<void> _connect(dynamic device) async {
    final vm = context.read<PrinterViewModel>();
    final ok = await vm.connect(device);
    if (!mounted) return;
    if (ok) {
      AppToast.show(context, 'Printer terhubung.');
      return;
    }

    // Gagal — tampilkan dialog dengan opsi
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gagal Koneksi', style: TextStyle(fontSize: 16)),
        content: const Text(
          'Gagal terhubung ke printer.\n\n'
          'Saran:\n'
          '1. Pastikan printer menyala (lampu hijau/biru).\n'
          '2. Matikan printer, nyalakan lagi.\n'
          '3. Jauhkan dari perangkat Bluetooth lain.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'disconnect'),
            child: const Text('Putuskan Paksa', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'retry'),
            child: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (choice == 'retry') {
      // Coba sekali lagi
      await _connect(device);
    } else if (choice == 'disconnect') {
      await vm.disconnect();
      if (mounted) {
        AppToast.show(context, 'Koneksi diputus. Coba hubungkan lagi.');
      }
    }
  }

  Future<void> _testPrint() async {
    final ok = await context.read<PrinterViewModel>().testPrint();
    if (!mounted) return;
    if (ok) {
      AppToast.show(context, 'Perintah cetak dikirim.');
    } else {
      await AppDialog.error(
        context,
        'Gagal cetak. Pastikan printer terhubung dan menyala.',
        title: 'Gagal Cetak',
      );
    }
  }

  Future<void> _scan() async {
    final vm = context.read<PrinterViewModel>();
    try {
      await vm.startScan();
      if (!mounted) return;
      if (vm.found.isEmpty) {
        await AppDialog.info(
          context,
          'Tidak ada device Bluetooth ditemukan.\nPastikan printer menyala dan dalam jangkauan.',
          title: 'Hasil Scan',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, e.toString(), title: 'Gagal Scan');
    }
  }

  Future<void> _pair(BtDeviceItem item) async {
    final vm = context.read<PrinterViewModel>();
    try {
      await vm.pairAndConnect(item.device);
      if (!mounted) return;
      AppToast.show(context, 'Pairing selesai.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(
        context,
        'Pairing gagal atau dibatalkan.\n$e',
        title: 'Gagal Pairing',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PrinterViewModel>();
    return Scaffold(
      appBar: AppAppBar(
        title: 'Pengaturan Printer',
        subtitle: 'Hubungkan printer Bluetooth',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => vm.load(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Status koneksi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        vm.isConnected ? Icons.print : Icons.print_disabled,
                        color: vm.isConnected
                            ? Colors.green
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vm.isConnected
                                  ? 'Terhubung'
                                  : 'Belum terhubung',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              vm.connected?.name ?? 'Pilih printer di bawah',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (vm.isConnected)
                        TextButton.icon(
                          onPressed: () => vm.disconnect(),
                          icon: const Icon(Icons.link_off, size: 14),
                          label: const Text('Putuskan',
                              style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Lebar kertas
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const Text('Lebar kertas',
                          style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        label: const Text('58mm',
                            style: TextStyle(fontSize: 11)),
                        selected: !vm.paper80mm,
                        onSelected: (_) => vm.setPaper80mm(false),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        label: const Text('80mm',
                            style: TextStyle(fontSize: 11)),
                        selected: vm.paper80mm,
                        onSelected: (_) => vm.setPaper80mm(true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tombol scan
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: vm.scanning ? null : _scan,
                        icon: vm.scanning
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.bluetooth_searching, size: 16),
                        label: Text(
                          vm.scanning
                              ? 'MENCARI...'
                              : 'CARI PRINTER BARU',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Printer terpairing (yang sudah bonded)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Printer Terpairing',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              if (vm.loading && vm.devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vm.devices.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Belum ada printer yang dipairing.\n'
                      'Gunakan tombol "Cari Printer Baru" di atas.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                )
              else
                ...vm.devices.map((d) {
                  final isCurrent = vm.connected?.address == d.address;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: const Icon(Icons.print, size: 18),
                      title: Text(d.name ?? '(no name)',
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(d.address ?? '',
                          style: const TextStyle(fontSize: 10)),
                      trailing: isCurrent
                          ? const Chip(
                              label: Text('Aktif',
                                  style: TextStyle(fontSize: 10)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            )
                          : TextButton(
                              onPressed: () => _connect(d),
                              child: const Text('Hubungkan',
                                  style: TextStyle(fontSize: 11)),
                            ),
                    ),
                  );
                }),

              // Hasil scan
              if (vm.found.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Device Ditemukan',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                ...vm.found.map((f) {
                  final isPaired = vm.devices
                      .any((d) => d.address == f.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(
                        isPaired ? Icons.bluetooth : Icons.bluetooth_searching,
                        size: 18,
                        color: isPaired
                            ? Colors.green
                            : Colors.grey.shade600,
                      ),
                      title: Text(f.name,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(f.id,
                          style: const TextStyle(fontSize: 10)),
                      trailing: isPaired
                          ? const Chip(
                              label: Text('Terpairing',
                                  style: TextStyle(fontSize: 10)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            )
                          : TextButton.icon(
                              onPressed: () => _pair(BtDeviceItem(f)),
                              icon: const Icon(Icons.link, size: 14),
                              label: const Text('Pair',
                                  style: TextStyle(fontSize: 11)),
                            ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 12),
              // Tombol tes cetak
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: vm.isConnected ? _testPrint : null,
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('TES CETAK',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BtDeviceItem {
  final BtDevice device;
  BtDeviceItem(this.device);
}
