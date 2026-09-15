import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
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
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductViewModel>().load();
      context.read<CategoryViewModel>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pvm = context.watch<ProductViewModel>();
    final cvm = context.watch<CategoryViewModel>();
    final cart = context.watch<CartViewModel>();

    final filtered = pvm.items.where((p) {
      if (_selectedCategoryId == null) return true;
      return p.categoryId == _selectedCategoryId;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Retail POS')),
      body: Row(
        children: [
          Expanded(
            flex: 68,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
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
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('Semua'),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategoryId = null),
                        ),
                      ),
                      ...cvm.items.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(c.name),
                            selected: _selectedCategoryId == c.id,
                            onSelected: (_) => setState(
                              () => _selectedCategoryId = c.id,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: pvm.loading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? const Center(child: Text('Belum ada produk.'))
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 6, 12),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 160,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final p = filtered[i];
                                final habis = p.stock <= 0;
                                return Opacity(
                                  opacity: habis ? 0.5 : 1,
                                  child: Card(
                                    margin: EdgeInsets.zero,
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
                                        padding: const EdgeInsets.all(8),
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
                                                      size: 30,
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
                                                          horizontal: 5,
                                                          vertical: 1,
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
                                                            fontSize: 9,
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
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              Currency.format(p.price),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Stok: ${p.stock.toStringAsFixed(0)} ${p.unit}',
                                              style:
                                                  const TextStyle(fontSize: 10),
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
          Expanded(
            flex: 32,
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
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, size: 20),
                const SizedBox(width: 6),
                const Text(
                  'Pesanan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Kosongkan', style: TextStyle(fontSize: 12)),
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
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Belum ada item.\nTap produk untuk menambahkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
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
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${Currency.format(it.product.price)} × ${it.quantity.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  icon: const Icon(
                                      Icons.remove_circle_outline, size: 20),
                                  onPressed: () =>
                                      context.read<CartViewModel>().decrease(
                                            it.product,
                                          ),
                                ),
                                Text(
                                  it.quantity.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
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
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (maxReached)
                              const Padding(
                                padding: EdgeInsets.only(left: 4, top: 0),
                                child: Text(
                                  'Stok maksimal',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
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
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text(
                      Currency.format(cart.subtotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed:
                        cart.isEmpty ? null : () => _openCheckout(context),
                    icon: const Icon(Icons.point_of_sale, size: 20),
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
      await AppDialog.error(context, e.toString(),
          title: 'Gagal Membuat Order');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paidAmount = double.tryParse(_paid.text.trim()) ?? 0;
    final change = paidAmount - widget.total;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomInset + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'cash', label: Text('Tunai')),
                            ButtonSegment(value: 'qris', label: Text('QRIS')),
                            ButtonSegment(value: 'card', label: Text('Kartu')),
                          ],
                          selected: {_method},
                          onSelectionChanged: (s) =>
                              setState(() => _method = s.first),
                        ),
                        const SizedBox(height: 10),
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
                          const SizedBox(height: 6),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _kv('Total', Currency.format(widget.total),
                            bold: true, size: 16),
                        const SizedBox(height: 6),
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
              const SizedBox(height: 14),
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
                      onPressed:
                          _busy ? null : () => _doPay(printAfter: false),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('BAYAR'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('BAYAR + CETAK'),
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

  Widget _kv(String label, String value,
      {bool bold = false, double size = 13, Color? color}) {
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
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => setState(() => _paid.text = value.toStringAsFixed(0)),
    );
  }
}
