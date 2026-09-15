import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';
import '../repositories/order_repository.dart';
import '../widgets/app_dialog.dart';
import 'receipt_view.dart';

class RetailPosView extends StatefulWidget {
  const RetailPosView({super.key});

  @override
  State<RetailPosView> createState() => _RetailPosViewState();
}

class _RetailPosViewState extends State<RetailPosView> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProductViewModel>().load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pvm = context.watch<ProductViewModel>();
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retail POS'),
      ),
      body: Row(
        children: [
          // ---- Panel kiri: grid produk ----
          Expanded(
            flex: 62,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _search,
                    onChanged: pvm.search,
                    decoration: const InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: pvm.loading
                      ? const Center(child: CircularProgressIndicator())
                      : pvm.items.isEmpty
                          ? const Center(child: Text('Belum ada produk.'))
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 6, 12),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 1.1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: pvm.items.length,
                              itemBuilder: (_, i) {
                                final p = pvm.items[i];
                                final habis = p.stock <= 0;
                                return Opacity(
                                  opacity: habis ? 0.5 : 1,
                                  child: Card(
                                    child: InkWell(
                                      onTap: habis
                                          ? () => AppDialog.error(
                                                context,
                                                'Produk ${p.name} habis.',
                                                title: 'Stok Habis',
                                              )
                                          : () => context
                                              .read<CartViewModel>()
                                              .add(p),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  Center(
                                                    child: Icon(
                                                      Icons.inventory_2,
                                                      size: 36,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                  if (habis)
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: const Text(
                                                          'HABIS',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              p.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              Currency.format(p.price),
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'Stok: ${p.stock.toStringAsFixed(0)} ${p.unit}',
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // ---- Panel kanan: pesanan ----
          Expanded(
            flex: 38,
            child: _OrderPanel(),
          ),
        ],
      ),
    );
  }
}

class _OrderPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.receipt_long),
                const SizedBox(width: 8),
                const Text(
                  'Pesanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Kosongkan'),
                    onPressed: () => context.read<CartViewModel>().clear(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada item.\nTap produk untuk menambahkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = cart.items[i];
                      final canPlus = cart.canIncrease(it.product);
                      final maxReached = !canPlus &&
                          cart.quantityOf(it.product) >= it.product.stock;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.product.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${Currency.format(it.product.price)} × ${it.quantity.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      context.read<CartViewModel>().decrease(
                                            it.product,
                                          ),
                                ),
                                Text(
                                  it.quantity.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    size: 22,
                                    color: canPlus ? null : Colors.grey,
                                  ),
                                  onPressed: canPlus
                                      ? () => context
                                          .read<CartViewModel>()
                                          .add(it.product)
                                      : null,
                                ),
                                const Spacer(),
                                Text(
                                  Currency.format(it.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (maxReached)
                              const Padding(
                                padding: EdgeInsets.only(left: 4, top: 2),
                                child: Text(
                                  'Stok maksimal',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 15)),
                    const Spacer(),
                    Text(
                      Currency.format(cart.subtotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: cart.isEmpty
                        ? null
                        : () => _openCheckout(context),
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('CHECKOUT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCheckout(BuildContext context) async {
    final cart = context.read<CartViewModel>();
    final auth = context.read<AuthViewModel>();
    if (cart.isEmpty || auth.currentUser?.id == null) return;

    final result = await showDialog<_CheckoutResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CheckoutDialog(
        total: cart.total,
        userId: auth.currentUser!.id!,
        items: cart.items.toList(),
      ),
    );

    if (result == null) return;
    cart.clear();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptView(orderId: result.orderId),
      ),
    );
  }
}

class _CheckoutResult {
  final int orderId;
  _CheckoutResult(this.orderId);
}

class _CheckoutDialog extends StatefulWidget {
  final double total;
  final int userId;
  final List items;

  const _CheckoutDialog({
    required this.total,
    required this.userId,
    required this.items,
  });

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  String _method = 'cash';
  final _paid = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _paid.text = widget.total.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _paid.dispose();
    super.dispose();
  }

  Future<void> _doPay({required bool printAfter}) async {
    final paidAmount = double.tryParse(_paid.text.trim()) ?? 0;
    if (paidAmount < widget.total) {
      await AppDialog.error(
        context,
        'Jumlah bayar kurang dari total.',
        title: 'Pembayaran Kurang',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final orderId = await OrderRepository.instance.createOrder(
        userId: widget.userId,
        items: widget.items.cast(),
        paymentMethod: _method,
        paidAmount: paidAmount,
      );
      if (!mounted) return;
      Navigator.pop(context, _CheckoutResult(orderId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await AppDialog.error(context, e.toString(), title: 'Gagal Membuat Order');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paidAmount = double.tryParse(_paid.text.trim()) ?? 0;
    final change = paidAmount - widget.total;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pembayaran',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kiri: metode + jumlah bayar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'cash', label: Text('Tunai')),
                          ButtonSegment(value: 'qris', label: Text('QRIS')),
                          ButtonSegment(value: 'card', label: Text('Kartu')),
                        ],
                        selected: {_method},
                        onSelectionChanged: (s) =>
                            setState(() => _method = s.first),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _paid,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Jumlah bayar',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      if (_method == 'cash') ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _quick('Uang Pas', widget.total),
                            _quick('50rb', 50000),
                            _quick('100rb', 100000),
                            _quick('150rb', 150000),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Kanan: ringkasan + kembalian
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _kv('Total', Currency.format(widget.total),
                          bold: true, size: 18),
                      const SizedBox(height: 8),
                      _kv('Bayar', Currency.format(paidAmount)),
                      const SizedBox(height: 4),
                      _kv(
                        'Kembalian',
                        Currency.format(change < 0 ? 0 : change),
                        bold: true,
                        color: Colors.green.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('BATAL'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _doPay(printAfter: false),
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('BAYAR'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: null, // placeholder 5b
                    icon: const Icon(Icons.print),
                    label: const Text('BAYAR + CETAK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value,
      {bool bold = false, double size = 14, Color? color}) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: size)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _quick(String label, double value) {
    return ActionChip(
      label: Text(label),
      onPressed: () => setState(() => _paid.text = value.toStringAsFixed(0)),
    );
  }
}
