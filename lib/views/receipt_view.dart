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
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: ListView(
                            padding: const EdgeInsets.all(8),
                            children: [
                              Card(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'POS v2',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Center(
                                        child: Text(
                                          _order!.invoiceNumber,
                                          style:
                                              const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                      const Divider(height: 16),
                                      ..._items.map(
                                        (it) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${it.productName} × ${it.quantity.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                      fontSize: 11),
                                                ),
                                              ),
                                              Text(
                                                Currency.format(it.subtotal),
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 16),
                                      _row('Subtotal', _order!.subtotal),
                                      _row('Diskon', _order!.discount),
                                      _row('Pajak', _order!.tax),
                                      _row('TOTAL', _order!.total, bold: true),
                                      const SizedBox(height: 4),
                                      _row('Bayar (${_order!.paymentMethod})',
                                          _order!.paidAmount),
                                      _row('Kembali', _order!.changeAmount),
                                      const Divider(height: 16),
                                      Center(
                                        child: Text(
                                          'Terima kasih',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade700,
                                            fontSize: 10,
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
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Aksi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 34,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                ),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 14),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('TRANSAKSI BARU',
                                      style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 34,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                ),
                                onPressed: () => AppDialog.info(
                                  context,
                                  'Fitur cetak struk akan aktif setelah printer Bluetooth terhubung.',
                                  title: 'Cetak Ulang',
                                ),
                                icon: const Icon(Icons.print, size: 14),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('CETAK ULANG',
                                      style: TextStyle(fontSize: 11)),
                                ),
                              ),
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
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            Currency.format(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
