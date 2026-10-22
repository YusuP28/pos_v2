import 'package:flutter/material.dart';

import '../widgets/app_appbar.dart';
import '../widgets/menu_card.dart';
import 'expense_view.dart';
import 'report/report_view.dart';
import 'shift/shift_history_view.dart';

/// Grup menu "Keuangan": laporan, pengeluaran, dan riwayat shift.
class KeuanganView extends StatelessWidget {
  const KeuanganView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Keuangan',
        subtitle: 'Laporan, pengeluaran & shift',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              MenuCard(
                icon: Icons.bar_chart,
                label: 'Laporan',
                subtitle: 'Penjualan & profit',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportView()),
                ),
              ),
              MenuCard(
                margin: const EdgeInsets.only(top: 8),
                icon: Icons.trending_down,
                label: 'Pengeluaran',
                subtitle: 'Catat biaya operasional kas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpenseView()),
                ),
              ),
              MenuCard(
                margin: const EdgeInsets.only(top: 8),
                icon: Icons.history,
                label: 'Riwayat Shift',
                subtitle: 'Shift lampau & rekap kas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShiftHistoryView()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
