import 'package:flutter/material.dart';

import '../../core/utils/currency.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/app_appbar.dart';
import '../receipt_view.dart';

enum ReportRange { today, week, month }

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  ReportRange _range = ReportRange.today;
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime) _rangeBounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case ReportRange.today:
        return (today, today.add(const Duration(days: 1)));
      case ReportRange.week:
        return (today.subtract(const Duration(days: 6)),
            today.add(const Duration(days: 1)));
      case ReportRange.month:
        return (today.subtract(const Duration(days: 29)),
            today.add(const Duration(days: 1)));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (start, end) = _rangeBounds();
    final orders = await OrderRepository.instance.getOrdersBetween(start, end);
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _orders.fold<double>(0, (s, o) => s + o.total);
    final cash = _orders
        .where((o) => o.paymentMethod == 'cash')
        .fold<double>(0, (s, o) => s + o.total);
    final qris = _orders
        .where((o) => o.paymentMethod == 'qris')
        .fold<double>(0, (s, o) => s + o.total);
    final card = _orders
        .where((o) => o.paymentMethod == 'card')
        .fold<double>(0, (s, o) => s + o.total);
    final avg = _orders.isEmpty ? 0.0 : total / _orders.length;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Laporan',
        subtitle: _rangeLabel(_range),
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
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    _rangeChip('Hari ini', ReportRange.today),
                    const SizedBox(width: 6),
                    _rangeChip('7 hari', ReportRange.week),
                    const SizedBox(width: 6),
                    _rangeChip('30 hari', ReportRange.month),
                  ],
                ),
              ),
              if (_loading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kiri: ringkasan
                      SizedBox(
                        width: 260,
                        child: ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            _summaryCard('Transaksi', '${_orders.length}'),
                            const SizedBox(height: 6),
                            _summaryCard('Total penjualan',
                                Currency.format(total),
                                bold: true, color: Colors.green.shade700),
                            const SizedBox(height: 6),
                            _summaryCard('Rata-rata',
                                Currency.format(avg)),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text('Metode pembayaran',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 6),
                            _summaryCard('Tunai', Currency.format(cash)),
                            const SizedBox(height: 6),
                            _summaryCard('QRIS', Currency.format(qris)),
                            const SizedBox(height: 6),
                            _summaryCard('Kartu', Currency.format(card)),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // Kanan: daftar transaksi
                      Expanded(
                        child: _orders.isEmpty
                            ? const Center(
                                child: Text('Tidak ada transaksi di periode ini.'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: _orders.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final o = _orders[i];
                                  final dt = o.createdAt
                                      .replaceFirst('T', ' ')
                                      .substring(0, 19);
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    leading: const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18),
                                    title: Text(o.invoiceNumber,
                                        style:
                                            const TextStyle(fontSize: 12)),
                                    subtitle: Text(
                                        '$dt  •  ${o.paymentMethod.toUpperCase()}',
                                        style:
                                            const TextStyle(fontSize: 10)),
                                    trailing: Text(
                                      Currency.format(o.total),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ReceiptView(orderId: o.id!),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rangeChip(String label, ReportRange r) {
    return FilterChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _range == r,
      onSelected: (_) {
        setState(() => _range = r);
        _load();
      },
    );
  }

  String _rangeLabel(ReportRange r) {
    switch (r) {
      case ReportRange.today:
        return 'Hari ini';
      case ReportRange.week:
        return '7 hari terakhir';
      case ReportRange.month:
        return '30 hari terakhir';
    }
  }

  Widget _summaryCard(String label, String value,
      {bool bold = false, Color? color}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
