import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/shift_viewmodel.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';
import 'shift_close_view.dart';

class ShiftView extends StatefulWidget {
  const ShiftView({super.key});

  @override
  State<ShiftView> createState() => _ShiftViewState();
}

class _ShiftViewState extends State<ShiftView> {
  final _openingCash = TextEditingController(text: '0');
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthViewModel>();
      context.read<ShiftViewModel>()
        ..pendingUserId = auth.currentUser?.id
        ..load();
    });
  }

  @override
  void dispose() {
    _openingCash.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _openShift() async {
    final cash = double.tryParse(_openingCash.text.trim()) ?? 0;
    try {
      await context.read<ShiftViewModel>().open(
            cash,
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      AppToast.show(context, 'Shift dibuka.');
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, e.toString(), title: 'Gagal Buka Shift');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShiftViewModel>();
    final shift = vm.current;
    final stats = vm.stats;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Shift Kas',
        subtitle: 'Buka / tutup kas',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : shift == null
                  ? _buildOpenForm()
                  : _buildActiveShift(shift, stats),
        ),
      ),
    );
  }

  Widget _buildOpenForm() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: ListTile(
            dense: true,
            leading: Icon(Icons.info_outline, size: 20),
            title: Text('Belum ada shift terbuka',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Buka shift untuk mulai menerima transaksi.',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Uang awal di drawer',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _openingCash,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Catatan (opsional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _notes,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Mis. shift pagi',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: _openShift,
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text('BUKA SHIFT'),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveShift(shift, stats) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_clock, color: Colors.green),
                    const SizedBox(width: 6),
                    const Text('Shift Aktif',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('OPEN',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _kv('Dibuka', shift.openedAt.replaceFirst('T', ' ').substring(0, 19)),
                _kv('Uang awal', Currency.format(shift.openingCash)),
                if (shift.notes.isNotEmpty) _kv('Catatan', shift.notes),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Ringkasan Penjualan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _kv('Jumlah transaksi', '${stats?.transactionCount ?? 0}'),
                _kv('Total penjualan',
                    Currency.format(stats?.totalSales ?? 0), bold: true),
                const Divider(height: 12),
                _kv('Tunai', Currency.format(stats?.cashSales ?? 0)),
                _kv('QRIS', Currency.format(stats?.qrisSales ?? 0)),
                _kv('Kartu', Currency.format(stats?.cardSales ?? 0)),
                const Divider(height: 12),
                _kv(
                  'Uang seharusnya',
                  Currency.format(
                      shift.openingCash + (stats?.cashSales ?? 0)),
                  bold: true,
                  color: Colors.green.shade700,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShiftCloseView(shiftId: shift.id!),
              ),
            ),
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('TUTUP SHIFT'),
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
