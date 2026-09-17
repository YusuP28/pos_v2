import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency.dart';
import '../../viewmodels/shift_viewmodel.dart';
import '../../widgets/app_appbar.dart';
import 'shift_detail_view.dart';

enum HistoryRange { today, week, month, custom }

class ShiftHistoryView extends StatefulWidget {
  const ShiftHistoryView({super.key});

  @override
  State<ShiftHistoryView> createState() => _ShiftHistoryViewState();
}

class _ShiftHistoryViewState extends State<ShiftHistoryView> {
  HistoryRange _range = HistoryRange.week;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  (DateTime?, DateTime?) _bounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case HistoryRange.today:
        return (today, today.add(const Duration(days: 1)));
      case HistoryRange.week:
        return (today.subtract(const Duration(days: 6)),
            today.add(const Duration(days: 1)));
      case HistoryRange.month:
        return (today.subtract(const Duration(days: 29)),
            today.add(const Duration(days: 1)));
      case HistoryRange.custom:
        if (_customRange != null) {
          return (
            _customRange!.start,
            _customRange!.end.add(const Duration(days: 1)),
          );
        }
        return (null, null);
    }
  }

  Future<void> _load() async {
    final (s, e) = _bounds();
    await context.read<ShiftViewModel>().loadHistory(start: s, end: e);
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _customRange,
      helpText: 'Pilih Rentang',
      saveText: 'PILIH',
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _range = HistoryRange.custom;
    });
    await _load();
  }

  String _label(HistoryRange r) {
    switch (r) {
      case HistoryRange.today:
        return 'Hari ini';
      case HistoryRange.week:
        return '7 hari';
      case HistoryRange.month:
        return '30 hari';
      case HistoryRange.custom:
        if (_customRange == null) return 'Kustom';
        return '${_customRange!.start.day}/${_customRange!.start.month} - '
            '${_customRange!.end.day}/${_customRange!.end.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShiftViewModel>();
    return Scaffold(
      appBar: AppAppBar(
        title: 'Riwayat Shift',
        subtitle: 'Daftar shift lampau',
        actions: [
          IconButton(
            tooltip: 'Kalender kustom',
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickCustom,
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
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    _chip('Hari ini', HistoryRange.today),
                    const SizedBox(width: 6),
                    _chip('7 hari', HistoryRange.week),
                    const SizedBox(width: 6),
                    _chip('30 hari', HistoryRange.month),
                    if (_range == HistoryRange.custom &&
                        _customRange != null) ...[
                      const SizedBox(width: 6),
                      FilterChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        label: Text(_label(HistoryRange.custom),
                            style: const TextStyle(fontSize: 11)),
                        selected: true,
                        onSelected: (_) => _pickCustom(),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: vm.historyLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.history.isEmpty
                        ? const Center(
                            child: Text('Belum ada shift di periode ini.',
                                style: TextStyle(fontSize: 12)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: vm.history.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final s = vm.history[i];
                              final diff = s.difference ?? 0;
                              final diffColor = s.isOpen
                                  ? Colors.grey
                                  : (diff == 0
                                      ? Colors.green.shade700
                                      : (diff > 0
                                          ? Colors.blue.shade700
                                          : Colors.red.shade700));
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: Icon(
                                  s.isOpen
                                      ? Icons.lock_open
                                      : Icons.lock_outline,
                                  size: 20,
                                  color: s.isOpen
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                ),
                                title: Text(
                                  s.openedAt
                                      .replaceFirst('T', ' ')
                                      .substring(0, 19),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  'Awal: ${Currency.format(s.openingCash)}'
                                  '${s.closingCash != null ? "  •  Akhir: ${Currency.format(s.closingCash!)}" : ""}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (s.isOpen)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('OPEN',
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold)),
                                      )
                                    else
                                      Text(
                                        'Selisih ${Currency.format(diff)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: diffColor,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ShiftDetailView(shiftId: s.id!),
                                  ),
                                ),
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

  Widget _chip(String label, HistoryRange r) {
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
}
