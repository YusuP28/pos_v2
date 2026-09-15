import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';
import '../repositories/order_repository.dart';
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

  Future<void> _openCart() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CartSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pvm = context.watch<ProductViewModel>();
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retail POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Kosongkan cart',
            onPressed: cart.isEmpty
                ? null
                : () => context.read<CartViewModel>().clear(),
          ),
        ],
      ),
      body: Column(
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
              ),
            ),
          ),
          Expanded(
            child: pvm.loading
                ? const Center(child: CircularProgressIndicator())
                : pvm.items.isEmpty
                    ? const Center(child: Text('Belum ada produk.'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: pvm.items.length,
                        itemBuilder: (_, i) {
                          final p = pvm.items[i];
                          return Card(
                            child: InkWell(
                              onTap: () =>
                                  context.read<CartViewModel>().add(p),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Icon(
                                          Icons.inventory_2,
                                          size: 42,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      p.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(Currency.format(p.price)),
                                    Text(
                                      'Stok: ${p.stock.toStringAsFixed(0)} ${p.unit}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomSheet: cart.isEmpty
          ? null
          : SafeArea(
              child: Material(
                elevation: 12,
                child: InkWell(
                  onTap: _openCart,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart),
                        const SizedBox(width: 8),
                        Text('${cart.itemCount} item'),
                        const Spacer(),
                        Text(
                          Currency.format(cart.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  const _CartSheet();

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<CartViewModel>();
    final auth = context.read<AuthViewModel>();
    if (cart.isEmpty) return;
    if (auth.currentUser?.id == null) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CheckoutSheet(total: cart.total),
    );
    if (result != true || !context.mounted) return;

    final paid = result == true
        ? context.read<CartViewModel>().total
        : 0.0;
    // Placeholder — tidak dipakai, checkout dilakukan di dalam sheet.
    // Lihat _CheckoutSheet._pay
    // ignore: unused_local_variable
    final _ = paid;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Keranjang',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('Keranjang kosong.'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cart.items.length,
                itemBuilder: (_, i) {
                  final it = cart.items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(it.product.name),
                    subtitle: Text(
                      '${Currency.format(it.product.price)} × ${it.quantity.toStringAsFixed(0)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => cart.decrease(it.product),
                        ),
                        Text(
                          it.quantity.toStringAsFixed(0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => cart.add(it.product),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(),
          Row(
            children: [
              const Text('Total', style: TextStyle(fontSize: 16)),
              const Spacer(),
              Text(
                Currency.format(cart.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: cart.isEmpty
                  ? null
                  : () async {
                      final total = cart.total;
                      final done = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => _CheckoutSheet(total: total),
                      );
                      if (done == true && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              icon: const Icon(Icons.point_of_sale),
              label: const Text('CHECKOUT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSheet extends StatefulWidget {
  final double total;
  const _CheckoutSheet({required this.total});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
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

  Future<void> _pay() async {
    final paidAmount = double.tryParse(_paid.text.trim()) ?? 0;
    if (paidAmount < widget.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah bayar kurang.')),
      );
      return;
    }

    final cart = context.read<CartViewModel>();
    final auth = context.read<AuthViewModel>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _busy = true);
    try {
      final orderId = await OrderRepository.instance.createOrder(
        userId: userId,
        items: cart.items.toList(),
        paymentMethod: _method,
        paidAmount: paidAmount,
      );
      cart.clear();
      if (!mounted) return;
      Navigator.pop(context, true);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReceiptView(orderId: orderId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paidAmount = double.tryParse(_paid.text.trim()) ?? 0;
    final change = paidAmount - widget.total;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pembayaran',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'cash', label: Text('Tunai')),
              ButtonSegment(value: 'qris', label: Text('QRIS')),
              ButtonSegment(value: 'card', label: Text('Kartu')),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paid,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Jumlah bayar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_method == 'cash')
            Wrap(
              spacing: 8,
              children: [
                _quick(context, 'Uang Pas', widget.total),
                _quick(context, '50.000', 50000),
                _quick(context, '100.000', 100000),
                _quick(context, '150.000', 150000),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Kembalian'),
              const Spacer(),
              Text(
                Currency.format(change < 0 ? 0 : change),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _pay,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_busy ? 'MEMPROSES...' : 'BAYAR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick(BuildContext context, String label, double value) {
    return ActionChip(
      label: Text(label),
      onPressed: () => setState(() => _paid.text = value.toStringAsFixed(0)),
    );
  }
}
