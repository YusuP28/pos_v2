import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency.dart';
import '../../models/shift.dart';
import '../../repositories/shift_repository.dart';
import '../../viewmodels/shift_viewmodel.dart';
import '../../widgets/app_appbar.dart';

class ShiftDetailView extends StatefulWidget {
  final int shiftId;
  const ShiftDetailView({super.key, required this.shiftId});

  @override
  State<ShiftDetailView> createState() => _ShiftDetailViewState();
}

class _ShiftDetailViewState extends State<ShiftDetailView> {
  Shift? _shift;
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ShiftRepository.instance.getById(widget.shiftId);
    final d = await context.read<ShiftViewModel>().getShiftDetail(widget.shiftId);
    if (!mounted) return;
    setState(() {
      _shift = s;
      _detail = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = _shift;
    if (s == null) {
      return Scaffold(
        appBar: AppAppBar(title: 'Detail Shift', subtitle: 'Tidak ditemukan'),
        body: const Center(child: Text('Shift tidak ditemukan.')),
      );
    }

    final stats = _detail?['stats'] as ShiftStats;
    final expenseTotal = (_detail?['expenseTotal'] as num?)?.toDouble() ?? 0;
    final expenses = (_detail?['expenses'] as List?) ?? [];

    final expected = s.expectedCash ??
        (s.openingCash + stats.cashSales - expenseTotal);
    final actual = s.closingCash ?? 0;
    final diff = s.difference ?? (actual - expected);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Detail Shift',
        subtitle: s.isOpen ? 'Sedang berjalan' : 'Sudah ditutup',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Info shift
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            s.isOpen ? Icons.lock_open : Icons.lock_outline,
                            color: s.isOpen ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.isOpen ? 'SHIFT OPEN' : 'SHIFT CLOSED',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: s.isOpen ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _kv('Dibuka',
                          s.openedAt.replaceFirst('T', ' ').substring(0, 19)),
                      if (s.closedAt != null)
                        _kv('Ditutup',
                            s.closedAt!.replaceFirst('T', ' ').substring(0, 19)),
                      _kv('Uang awal', Currency.format(s.openingCash)),
                      if (s.notes.isNotEmpty) _kv('Catatan', s.notes),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Ringkasan penjualan
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text('Ringkasan Penjualan',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _kv('Jumlah transaksi', '${stats.transactionCount}'),
                      _kv('Total penjualan',
                          Currency.format(stats.totalSales), bold: true),
                      const Divider(height: 12),
                      _kv('Tunai', Currency.format(stats.cashSales)),
                      _kv('QRIS', Currency.format(stats.qrisSales)),
                      _kv('Kartu', Currency.format(stats.cardSales)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Pengeluaran
              if (expenses.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text('Pengeluaran',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ...expenses.map<Widget>((e) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${e['category']}${(e['notes'] as String).isNotEmpty ? " - ${e['notes']}" : ""}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    Currency.format(
                                        (e['amount'] as num).toDouble()),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 12),
                        _kv('Total pengeluaran',
                            Currency.format(expenseTotal),
                            bold: true, color: Colors.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Rekap uang
              if (!s.isOpen) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text('Rekap Uang',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _kv('Uang awal', Currency.format(s.openingCash)),
                        _kv('Penjualan tunai',
                            Currency.format(stats.cashSales)),
                        _kv('Pengeluaran',
                            '- ${Currency.format(expenseTotal)}',
                            color: Colors.red),
                        const Divider(height: 12),
                        _kv('Uang seharusnya', Currency.format(expected),
                            bold: true, color: Colors.green.shade700),
                        _kv('Uang fisik', Currency.format(actual),
                            bold: true),
                        const Divider(height: 12),
                        _kv(
                          'Selisih',
                          Currency.format(diff),
                          bold: true,
                          color: diff == 0
                              ? Colors.green.shade700
                              : (diff > 0
                                  ? Colors.blue.shade700
                                  : Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
