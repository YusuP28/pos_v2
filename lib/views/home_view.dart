import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/printer_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/shift_viewmodel.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_toast.dart';
import '../widgets/menu_card.dart';
import 'kategori_grup_view.dart';
import 'keuangan_view.dart';
import 'login_view.dart';
import 'operasional_view.dart';
import 'pengaturan_view.dart';
import 'retail_pos_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthViewModel>();
      context.read<ShiftViewModel>()
        ..pendingUserId = auth.currentUser?.id
        ..load();
      context.read<PrinterViewModel>()
        ..load(silent: true)
        ..autoConnect();
      context.read<SettingsViewModel>().load();
      _checkBluetooth();
    });
  }

  Future<void> _checkBluetooth() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        if (!mounted) return;
        AppToast.show(
          context,
          'Bluetooth belum aktif. Nyalakan untuk printer.',
          success: false,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (_) {}
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppAppBar(
        title: 'POS v2',
        subtitle: 'Selamat datang',
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout?',
                      style: TextStyle(fontSize: 16)),
                  content: Text(
                    'Anda akan keluar dari akun "${user?.fullName ?? user?.username ?? '-'}".'
                    '\n\nSetelah logout, Anda harus login ulang dengan '
                    'username & password.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal',
                          style: TextStyle(fontSize: 12)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              if (!context.mounted) return;
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading:
                      const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 14)),
                  title: Text(
                    'Halo, ${user?.fullName ?? "-"}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    'Role: ${user?.role ?? "-"}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('Menu',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.0,
                children: [
                  MenuCard(
                    icon: Icons.point_of_sale,
                    label: 'Retail POS',
                    onTap: () => _push(context, const RetailPosView()),
                  ),
                  MenuCard(
                    icon: Icons.inventory_2,
                    label: 'Katalog',
                    onTap: () => _push(context, const KatalogView()),
                  ),
                  MenuCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Keuangan',
                    onTap: () => _push(context, const KeuanganView()),
                  ),
                  MenuCard(
                    icon: Icons.schedule,
                    label: 'Operasional',
                    onTap: () => _push(context, const OperasionalView()),
                  ),
                  MenuCard(
                    icon: Icons.settings,
                    label: 'Pengaturan',
                    onTap: () => _push(context, const PengaturanView()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
