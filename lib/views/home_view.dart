import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'category_list_view.dart';
import 'login_view.dart';
import 'product_list_view.dart';
import 'retail_pos_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS v2'),
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
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  dense: true,
                  leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                  title: Text('Halo, ${user?.fullName ?? "-"}'),
                  subtitle: Text('Role: ${user?.role ?? "-"}'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Menu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
