import 'package:flutter/material.dart';

import '../widgets/app_appbar.dart';
import '../widgets/menu_card.dart';
import '../widgets/pin_admin_gate.dart';
import 'info_toko_view.dart';
import 'printer_settings_view.dart';
import 'settings_view.dart';
import 'user/user_management_view.dart';

/// Grup menu "Pengaturan": printer, info toko, user, dan pengaturan aplikasi.
///
/// Menu yang butuh hak admin tetap melewati [openAdminMenu].
class PengaturanView extends StatelessWidget {
  const PengaturanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Pengaturan',
        subtitle: 'Printer, toko & user',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              MenuCard(
                icon: Icons.print,
                label: 'Pengaturan Printer',
                subtitle: 'Hubungkan printer Bluetooth',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrinterSettingsView()),
                ),
              ),
              MenuCard(
                margin: const EdgeInsets.only(top: 8),
                icon: Icons.store,
                label: 'Info Toko',
                subtitle: 'Nama, alamat, logo & QRIS',
                locked: true,
                onTap: () => openAdminMenu(
                  context,
                  (_) => const InfoTokoView(),
                ),
              ),
              MenuCard(
                margin: const EdgeInsets.only(top: 8),
                icon: Icons.people,
                label: 'Manajemen User',
                subtitle: 'Kasir & admin',
                locked: true,
                onTap: () => openAdminMenu(
                  context,
                  (_) => const UserManagementView(),
                ),
              ),
              MenuCard(
                margin: const EdgeInsets.only(top: 8),
                icon: Icons.settings,
                label: 'Pengaturan',
                subtitle: 'PIN, backup, export & versi',
                locked: true,
                onTap: () => openAdminMenu(
                  context,
                  (_) => const SettingsView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
