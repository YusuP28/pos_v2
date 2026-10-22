import 'package:flutter/material.dart';

import '../widgets/app_appbar.dart';
import '../widgets/menu_card.dart';
import 'shift_view.dart';

/// Grup menu "Operasional": buka/tutup shift kas.
class OperasionalView extends StatelessWidget {
  const OperasionalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Operasional',
        subtitle: 'Operasional toko',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              MenuCard(
                icon: Icons.account_balance_wallet,
                label: 'Shift Kas',
                subtitle: 'Buka / tutup kas & rekonsiliasi',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShiftView()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
