import 'package:flutter/material.dart';

import '../widgets/app_appbar.dart';
import '../widgets/menu_card.dart';
import 'category_list_view.dart';
import 'product_list_view.dart';
import 'stock/stock_report_view.dart';

/// Grup menu "Katalog": produk, kategori produk, dan laporan stok.
class KatalogView extends StatelessWidget {
  const KatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Katalog',
        subtitle: 'Produk, kategori & stok',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              MenuCard(
                icon: Icons.inventory_2,
                label: 'Produk',
                subtitle: 'Kelola produk, harga, dan stok',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListView()),
                ),
              ),
              MenuCard(
                margin: const EdgeInsets.only(top: 8),
                icon: Icons.category,
                label: 'Kategori',
                subtitle: 'Kelompok produk',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryListView()),
                ),
              ),
              MenuCard(
                margin: const EdgeInsets.only(top: 8),
                icon: Icons.inventory,
                label: 'Laporan Stok',
                subtitle: 'Stok minimum & riwayat pergerakan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockReportView()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
