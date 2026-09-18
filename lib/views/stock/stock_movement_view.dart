import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../repositories/stock_repository.dart';
import '../../widgets/app_appbar.dart';

class StockMovementView extends StatefulWidget {
  final Product product;
  const StockMovementView({super.key, required this.product});

  @override
  State<StockMovementView> createState() => _StockMovementViewState();
}

class _StockMovementViewState extends State<StockMovementView> {
  List<StockMovement> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items =
        await StockRepository.instance.getByProduct(widget.product.id!);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppAppBar(
        title: p.name,
        subtitle: 'Riwayat pergerakan stok',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              // Ringkasan
              Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 24),
                      const SizedBox(width: 8),
                      const Text('Stok saat ini',
                          style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      Text(
                        '${p.stock.toStringAsFixed(0)} ${p.unit}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Riwayat
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? const Center(
                            child: Text('Belum ada pergerakan stok.',
                                style: TextStyle(fontSize: 12)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final m = _items[i];
                              final dt = m.createdAt
                                  .replaceFirst('T', ' ')
                                  .substring(0, 19);
                              final isIn = m.type == 'in';
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: Icon(
                                  isIn ? Icons.add_circle : Icons.remove_circle,
                                  color:
                                      isIn ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                title: Text(
                                  '${isIn ? "+" : "-"}${m.quantity.toStringAsFixed(0)} ${p.unit}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isIn ? Colors.green : Colors.red,
                                  ),
                                ),
                                subtitle: Text(
                                  m.notes.isEmpty ? dt : '$dt  •  ${m.notes}',
                                  style: const TextStyle(fontSize: 10),
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
}
