import 'package:flutter/material.dart';

import '../core/utils/currency.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../repositories/order_repository.dart';
import '../widgets/app_dialog.dart';

class ReceiptView extends StatefulWidget {
  final int orderId;
  const ReceiptView({super.key, required this.orderId});

  @override
  State<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends State<ReceiptView> {
  Order? _order;
  List<OrderItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await OrderRepository.instance.getById(widget.orderId);
    final items = await OrderRepository.instance.getItems(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = o;
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Struk')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order tidak ditemukan.'))
              : Row(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: Text(
                                      'POS v2',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      _order!.invoiceNumber,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  ..._items.map(
                                    (it) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${it.productName} × ${it.quantity.toStringAsFixed(0)}',
                                            ),
                                          ),
                                          Text(Currency.format(it.subtotal)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  _row('Subtotal', _order!.subtotal),
                                  _row('Diskon', _order!.discount),
                                  _row('Pajak', _order!.tax),
                                  _row('TOTAL', _order!.total, bold: true),
                                  const SizedBox(height: 8),
                                  _row(
                                      'Bayar (${_order!.paymentMethod})',
                                      _order!.paidAmount),
                                  _row('Kembali', _order!.changeAmount),
                                  const Divider(height: 24),
                                  Center(
                                    child: Text(
                                      'Terima kasih',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Aksi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('TRANSAKSI BARU'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => AppDialog.info(
                                context,
                                'Fitur cetak struk akan aktif setelah printer Bluetooth terhubung.',
                                title: 'Cetak Ulang',
                              ),
                              icon: const Icon(Icons.print),
                              label: const Text('CETAK ULANG STRUK'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            Currency.format(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
