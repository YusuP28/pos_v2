import 'package:flutter/material.dart';

import '../../core/utils/currency.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/app_appbar.dart';
import '../receipt_view.dart';

enum ReportRange { today, week, month, custom }

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  ReportRange _range = ReportRange.today;
  DateTimeRange? _customRange;
  List<Order> _orders = [];
  bool _loading = true;
  final _search = TextEditingController();
  String _query = '';
  String? _methodFilter; // 'cash' | 'qris' | 'card' | null

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
      case ReportRange.custom:
        if (_customRange != null) {
          return (
            _customRange!.start,
            _customRange!.end.add(const Duration(days: 1)),
          );
        }
        return (today, today.add(const Duration(days: 1)));
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

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _customRange,
      helpText: 'Pilih Rentang Tanggal',
      saveText: 'PILIH',
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _range = ReportRange.custom;
    });
    await _load();
  }

  List<Order> get _filtered {
    return _orders.where((o) {
      if (_methodFilter != null && o.paymentMethod != _methodFilter) {
        return false;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!o.invoiceNumber.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  String _rangeLabel(ReportRange r) {
    switch (r) {
      case ReportRange.today:
        return 'Hari ini';
      case ReportRange.week:
        return '7 hari terakhir';
      case ReportRange.month:
        return '30 hari terakhir';
      case ReportRange.custom:
        if (_customRange == null) return 'Kustom';
        final s = _customRange!.start;
        final e = _customRange!.end;
        return '${s.day}/${s.month}/${s.year} - ${e.day}/${e.month}/${e.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filtered;
    final total = orders.fold<double>(0, (s, o) => s + o.total);
    final cash = orders
        .where((o) => o.paymentMethod == 'cash')
        .fold<double>(0, (s, o) => s + o.total);
    final qris = orders
        .where((o) => o.paymentMethod == 'qris')
        .fold<double>(0, (s, o) => s + o.total);
    final card = orders
        .where((o) => o.paymentMethod == 'card')
        .fold<double>(0, (s, o) => s + o.total);
    final avg = orders.isEmpty ? 0.0 : total / orders.length;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Laporan',
        subtitle: _rangeLabel(_range),
        actions: [
          IconButton(
            tooltip: 'Kalender (rentang kustom)',
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickCustomRange,
          ),
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
              // Chip rentang
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    _rangeChip('Hari ini', ReportRange.today),
                    const SizedBox(width: 6),
                    _rangeChip('7 hari', ReportRange.week),
                    const SizedBox(width: 6),
                    _rangeChip('30 hari', ReportRange.month),
                    if (_range == ReportRange.custom &&
                        _customRange != null) ...[
                      const SizedBox(width: 6),
                      FilterChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        label: Text(_rangeLabel(ReportRange.custom),
                            style: const TextStyle(fontSize: 11)),
                        selected: true,
                        onSelected: (_) => _pickCustomRange(),
                      ),
                    ],
                  ],
                ),
              ),

              // Search + filter metode
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Cari no. invoice...',
                          hintStyle: TextStyle(fontSize: 12),
                          prefixIcon: Icon(Icons.search, size: 18),
                          prefixIconConstraints:
                              BoxConstraints(minWidth: 32, minHeight: 32),
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _methodChip('Tunai', 'cash'),
                    const SizedBox(width: 4),
                    _methodChip('QRIS', 'qris'),
                    const SizedBox(width: 4),
                    _methodChip('Kartu', 'card'),
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
                      // Ringkasan
                      SizedBox(
                        width: 260,
                        child: ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            _summaryCard('Transaksi', '${orders.length}'),
                            const SizedBox(height: 6),
                            _summaryCard('Total', Currency.format(total),
                                bold: true, color: Colors.green.shade700),
                            const SizedBox(height: 6),
                            _summaryCard('Rata-rata', Currency.format(avg)),
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
                      // Daftar transaksi
                      Expanded(
                        child: orders.isEmpty
                            ? const Center(
                                child: Text(
                                    'Tidak ada transaksi di periode ini.'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: orders.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final o = orders[i];
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

  Widget _methodChip(String label, String method) {
    return FilterChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _methodFilter == method,
      onSelected: (_) {
        setState(() {
          _methodFilter = _methodFilter == method ? null : method;
        });
      },
    );
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
