import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/printer_viewmodel.dart';
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
    if (!ok) {
      await AppDialog.error(
        context,
        'Gagal terhubung ke printer. Pastikan printer menyala dan sudah dipairing.',
        title: 'Gagal Koneksi',
      );
    }
  }

  Future<void> _testPrint() async {
    final ok = await context.read<PrinterViewModel>().testPrint();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perintah cetak dikirim.')),
      );
    } else {
      await AppDialog.error(
        context,
        'Gagal cetak. Pastikan printer terhubung dan menyala.',
        title: 'Gagal Cetak',
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
          constraints: const BoxConstraints(maxWidth: 720),
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
                        vm.isConnected
                            ? Icons.print
                            : Icons.print_disabled,
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

              // Daftar printer paired
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Printer Terpairing',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              if (vm.loading)
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
                      'Pairing lewat Settings → Bluetooth terlebih dahulu.',
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
