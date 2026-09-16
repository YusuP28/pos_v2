import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/printer_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/shift_viewmodel.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_toast.dart';
import 'category_list_view.dart';
import 'login_view.dart';
import 'product_list_view.dart';
import 'retail_pos_view.dart';
import 'report/report_view.dart';
import 'info_toko_view.dart';
import 'printer_settings_view.dart';
import 'settings_view.dart';
import 'shift_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
            onPressed: () {
              auth.logout();
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
                  leading: const CircleAvatar(
                      radius: 14, child: Icon(Icons.person, size: 14)),
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
                child: Text(
                  'Menu',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
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
                  _MenuCard(
                    icon: Icons.point_of_sale,
                    label: 'Retail POS',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RetailPosView()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.inventory_2,
                    label: 'Produk',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductListView()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.category,
                    label: 'Kategori',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoryListView()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Shift Kas',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShiftView()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.bar_chart,
                    label: 'Laporan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportView()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.print,
                    label: 'Pengaturan Printer',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrinterSettingsView()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.store,
                    label: 'Info Toko',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InfoTokoView()),
                    ),
                  ),
                  _MenuCard(
                    icon: Icons.settings,
                    label: 'Pengaturan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsView()),
                    ),
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

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
