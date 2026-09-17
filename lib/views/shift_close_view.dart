import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../core/database/db_helper.dart';
import '../models/shift.dart';
import '../repositories/shift_repository.dart';
import '../viewmodels/shift_viewmodel.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';

class ShiftCloseView extends StatefulWidget {
  final int shiftId;
  const ShiftCloseView({super.key, required this.shiftId});

  @override
  State<ShiftCloseView> createState() => _ShiftCloseViewState();
}

class _ShiftCloseViewState extends State<ShiftCloseView> {
  final _closingCash = TextEditingController(text: '0');
  final _notes = TextEditingController();
  Shift? _shift;
  ShiftStats? _stats;
  double _expenseTotal = 0;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _closingCash.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<double> _getExpenseTotal(int shiftId) async {
    try {
      final db = await DbHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE shift_id = ?',
        [shiftId],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _load() async {
    final s = await ShiftRepository.instance.getById(widget.shiftId);
    final stats = await ShiftRepository.instance.getStats(widget.shiftId);
    final expenseTotal = await _getExpenseTotal(widget.shiftId);
    if (!mounted) return;
    setState(() {
      _shift = s;
      _stats = stats;
      _expenseTotal = expenseTotal;
      _loading = false;
    });
  }

  Future<void> _close() async {
    final cash = double.tryParse(_closingCash.text.trim()) ?? 0;
    setState(() => _busy = true);
    try {
      final closed = await context.read<ShiftViewModel>().close(
            cash,
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      await _showRekap(closed);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      await AppDialog.error(context, e.toString(), title: 'Gagal Tutup Shift');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showRekap(Shift closed) async {
    final expected = closed.expectedCash ?? 0;
    final diff = closed.difference ?? 0;
    final diffColor = diff == 0
        ? Colors.green.shade700
        : (diff > 0 ? Colors.blue.shade700 : Colors.red.shade700);

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(ctx).size.height - 80,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Rekap Shift',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Konten scrollable agar tidak overflow
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _row('Uang awal', closed.openingCash),
                        _row('Penjualan tunai', _stats?.cashSales ?? 0),
                        _row('Pengeluaran', -_expenseTotal,
                            color: Colors.red),
                        const Divider(height: 16),
                        _row('Uang seharusnya', expected, bold: true),
                        _row('Uang fisik', closed.closingCash ?? 0,
                            bold: true),
                        const Divider(height: 16),
                        _row('Selisih', diff,
                            bold: true, color: diffColor),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            diff == 0
                                ? '✓ Kas cocok'
                                : diff > 0
                                    ? '↑ Kas lebih'
                                    : '↓ Kas kurang',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: diffColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tombol OK sebagai bagian dari Column (bukan actions)
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text(
            Currency.format(value),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final shift = _shift;
    if (shift == null) {
      return Scaffold(
        appBar: AppAppBar(title: 'Tutup Shift', subtitle: 'Shift tidak ditemukan'),
        body: const Center(child: Text('Shift tidak ditemukan.')),
      );
    }
    final stats = _stats!;
    final expected = shift.openingCash + stats.cashSales - _expenseTotal;
    final cash = double.tryParse(_closingCash.text.trim()) ?? 0;
    final diff = cash - expected;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Tutup Shift',
        subtitle: 'Hitung uang fisik',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _row('Uang awal', shift.openingCash),
                      _row('Penjualan tunai', stats.cashSales),
                      _row('Penjualan QRIS', stats.qrisSales),
                      _row('Penjualan kartu', stats.cardSales),
                      _row('Pengeluaran', -_expenseTotal),
                      const Divider(height: 12),
                      _row('Uang seharusnya', expected, bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Uang fisik di drawer',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _closingCash,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('Selisih', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text(
                    Currency.format(diff),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: diff == 0
                          ? Colors.green.shade700
                          : (diff > 0
                              ? Colors.blue.shade700
                              : Colors.red.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Catatan (opsional)',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Mis. ada selisih Rp 500',
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
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  onPressed: _busy ? null : _close,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock, size: 18),
                  label: Text(_busy ? 'MENUTUP...' : 'TUTUP SHIFT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
