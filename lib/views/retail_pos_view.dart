import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/printer_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/shift_viewmodel.dart';
import '../repositories/order_repository.dart';
import '../widgets/app_appbar.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_toast.dart';
import 'scanner/barcode_scanner_view.dart';
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
      context.read<SettingsViewModel>().load();
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

    final filtered = pvm.items.where((p) {
      if (_selectedCategoryId == null) return true;
      return p.categoryId == _selectedCategoryId;
    }).toList();

    return Scaffold(
      appBar: AppAppBar(
        title: 'Retail POS',
        subtitle: 'Mode kasir / penjualan',
        actions: [
          IconButton(
            tooltip: 'Scan barcode',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _scanBarcode(context),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 68,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: TextField(
                    controller: _search,
                    onChanged: pvm.search,
                    decoration: const InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: TextStyle(fontSize: 12),
                      prefixIcon: Icon(Icons.search, size: 18),
                      prefixIconConstraints:
                          BoxConstraints(minWidth: 32, minHeight: 32),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FilterChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: const Text('Semua',
                              style: TextStyle(fontSize: 11)),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategoryId = null),
                        ),
                      ),
                      ...cvm.items.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FilterChip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: Text(c.name,
                                style: const TextStyle(fontSize: 11)),
                            selected: _selectedCategoryId == c.id,
                            onSelected: (_) =>
                                setState(() => _selectedCategoryId = c.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: pvm.loading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? const Center(child: Text('Belum ada produk.'))
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                // Adaptif: min 3 kolom, max 10 kolom, target ~130dp per kartu
                                final cols = (constraints.maxWidth / 105)
                                    .floor()
                                    .clamp(3, 12);
                                return GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    childAspectRatio: 1.05,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
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
                                            padding: const EdgeInsets.all(6),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Center(
                                                  child: Icon(
                                                    Icons.inventory_2,
                                                    size: 22,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  p.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    height: 1.1,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  Currency.format(p.price),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  'Stok ${p.stock.toStringAsFixed(0)} ${p.unit}',
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                                if (habis)
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.only(top: 2),
                                                    child: Text(
                                                      'HABIS',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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

  Future<void> _scanBarcode(BuildContext context) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
    if (code == null || code.isEmpty || !context.mounted) return;

    final clean = code.trim();
    final product =
        await context.read<ProductViewModel>().findByBarcode(clean);

    if (product == null) {
      if (!context.mounted) return;
      await AppDialog.error(
        context,
        'Barcode "$code" tidak ditemukan di database produk.',
        title: 'Produk Tidak Ditemukan',
      );
      return;
    }

    if (product.stock <= 0) {
      if (!context.mounted) return;
      await AppDialog.error(
        context,
        'Produk ${product.name} habis.',
        title: 'Stok Habis',
      );
      return;
    }

    if (!context.mounted) return;
    context.read<CartViewModel>().add(product);
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
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Pesanan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_sweep, size: 14),
                    label:
                        const Text('Kosong', style: TextStyle(fontSize: 11)),
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
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Belum ada item.\nTap produk untuk menambahkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = cart.items[i];
                      final canPlus = cart.canIncrease(it.product);
                      final maxReached = !canPlus &&
                          cart.quantityOf(it.product) >= it.product.stock;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${Currency.format(it.product.price)} × ${it.quantity.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 26, minHeight: 26),
                                  icon: const Icon(
                                      Icons.remove_circle_outline, size: 18),
                                  onPressed: () =>
                                      context.read<CartViewModel>().decrease(
                                            it.product,
                                          ),
                                ),
                                Text(
                                  it.quantity.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 26, minHeight: 26),
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    size: 18,
                                    color: canPlus ? null : Colors.grey,
                                  ),
                                  onPressed: canPlus
                                      ? () => context
                                          .read<CartViewModel>()
                                          .add(it.product)
                                      : null,
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 26, minHeight: 26),
                                  icon: Icon(
                                    Icons.percent,
                                    size: 16,
                                    color: it.discountType != DiscountType.none
                                        ? Colors.orange
                                        : null,
                                  ),
                                  onPressed: () => _openDiscountDialog(context, it),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (it.discountType != DiscountType.none) ...[
                                        Text(
                                          Currency.format(it.subtotal),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        Text(
                                          '- ${Currency.format(it.discountAmount)}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        Currency.format(it.total),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: it.discountType != DiscountType.none
                                              ? Colors.green.shade700
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (maxReached)
                              const Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: Text(
                                  'Stok maksimal',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 9,
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
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text(
                      Currency.format(cart.subtotal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (cart.totalDiscount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Diskon', style: TextStyle(fontSize: 12, color: Colors.red)),
                      const Spacer(),
                      Text(
                        '- ${Currency.format(cart.totalDiscount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        Currency.format(cart.total),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed:
                        cart.isEmpty ? null : () => _openCheckout(context),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child:
                          Text('CHECKOUT', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDiscountDialog(BuildContext context, CartItem item) async {
    final percentCtrl = TextEditingController(
      text: item.discountType == DiscountType.percent && item.discountValue > 0
          ? item.discountValue.toStringAsFixed(0)
          : '',
    );
    final nominalCtrl = TextEditingController(
      text: item.discountType == DiscountType.nominal && item.discountValue > 0
          ? item.discountValue.toStringAsFixed(0)
          : '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diskon Item', style: TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Harga: ${Currency.format(item.subtotal)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text('Diskon (%)', style: TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              TextField(
                controller: percentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 10',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Diskon (Rp)', style: TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              TextField(
                controller: nominalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 5000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {'type': DiscountType.none, 'value': 0.0}),
            child: const Text('Hapus Diskon', style: TextStyle(fontSize: 12, color: Colors.red)),
          ),
          FilledButton(
            onPressed: () {
              final p = double.tryParse(percentCtrl.text) ?? 0;
              final n = double.tryParse(nominalCtrl.text) ?? 0;
              if (p > 0) {
                Navigator.pop(ctx, {'type': DiscountType.percent, 'value': p.clamp(0, 100)});
              } else if (n > 0) {
                Navigator.pop(ctx, {'type': DiscountType.nominal, 'value': n});
              } else {
                Navigator.pop(ctx, {'type': DiscountType.none, 'value': 0.0});
              }
            },
            child: const Text('Simpan', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (result != null) {
      final type = result['type'] as DiscountType;
      final value = result['value'] as double;
      if (type == DiscountType.none || value == 0) {
        if (!context.mounted) return;
        context.read<CartViewModel>().setDiscount(item.product, DiscountType.none, 0);
      } else if (value > 20 && type == DiscountType.percent) {
        // PIN admin jika diskon > 20%
        if (!context.mounted) return;
        final pinOk = await _askAdminPin(context);
        if (pinOk == true) {
          if (!context.mounted) return;
          context.read<CartViewModel>().setDiscount(item.product, type, value);
        }
      } else {
        if (!context.mounted) return;
        context.read<CartViewModel>().setDiscount(item.product, type, value);
      }
    }
  }

  Future<bool?> _askAdminPin(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PIN Admin', style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'PIN 6-digit',
            border: OutlineInputBorder(),
            isDense: true,
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _openCheckout(BuildContext context) async {
    final cart = context.read<CartViewModel>();
    final auth = context.read<AuthViewModel>();
    final shift = context.read<ShiftViewModel>();
    if (cart.isEmpty || auth.currentUser?.id == null) return;

    if (!shift.hasOpenShift) {
      await AppDialog.error(
        context,
        'Belum ada shift terbuka.\nBuka shift dulu di menu Shift Kas.',
        title: 'Shift Belum Dibuka',
      );
      return;
    }

    final result = await showDialog<_CheckoutResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CheckoutDialog(
        total: cart.total,
        userId: auth.currentUser!.id!,
        shiftId: shift.current!.id!,
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
  final int shiftId;
  final List items;

  const _CheckoutDialog({
    required this.total,
    required this.userId,
    required this.shiftId,
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
    if (_method == 'cash' && paidAmount < widget.total) {
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
        shiftId: widget.shiftId,
        items: widget.items.cast(),
        paymentMethod: _method,
        paidAmount: (_method == 'qris' || _method == 'card')
            ? widget.total
            : paidAmount,
      );

      if (printAfter) {
        final printer = context.read<PrinterViewModel>();
        if (printer.isConnected) {
          try {
            final order =
                await OrderRepository.instance.getById(orderId);
            final orderItems =
                await OrderRepository.instance.getItems(orderId);
            if (order != null) {
              await printer.printReceipt(
                invoiceNumber: order.invoiceNumber,
                cashierName: '-',
                dateTime: order.createdAt
                    .replaceFirst('T', ' ')
                    .substring(0, 19),
                items: orderItems
                    .map((it) => {
                          'name': it.productName,
                          'qty': it.quantity,
                          'price': it.price,
                        })
                    .toList(),
                subtotal: order.subtotal,
                total: order.total,
                paymentMethod: order.paymentMethod,
                paidAmount: order.paidAmount,
                changeAmount: order.changeAmount,
              );
            }
          } catch (_) {}
        } else {
          if (mounted) {
            AppToast.show(
              context,
              'Printer belum terhubung. Transaksi tetap tersimpan.',
              success: false,
            );
          }
        }
      }

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
    final isQris = _method == 'qris';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: bottomInset + 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          segments: const [
                            ButtonSegment(
                                value: 'cash',
                                label: Text('Tunai',
                                    style: TextStyle(fontSize: 11))),
                            ButtonSegment(
                                value: 'qris',
                                label: Text('QRIS',
                                    style: TextStyle(fontSize: 11))),
                            ButtonSegment(
                                value: 'card',
                                label: Text('Kartu',
                                    style: TextStyle(fontSize: 11))),
                          ],
                          selected: {_method},
                          onSelectionChanged: (s) =>
                              setState(() => _method = s.first),
                        ),
                        const SizedBox(height: 8),
                        if (isQris)
                          _buildQrisContent(context)
                        else if (_method == 'card')
                          _buildCardContent()
                        else ...[
                          TextField(
                            controller: _paid,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Jumlah bayar',
                              labelStyle: TextStyle(fontSize: 12),
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                          if (_method == 'cash') ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                _quick('Uang Pas', widget.total),
                                _quick('50rb', 50000),
                                _quick('100rb', 100000),
                                _quick('150rb', 150000),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _kv('Total', Currency.format(widget.total),
                            bold: true, size: 14),
                        const SizedBox(height: 4),
                        if (!isQris) ...[
                          _kv('Bayar', Currency.format(paidAmount), size: 12),
                          const SizedBox(height: 2),
                          _kv(
                            'Kembalian',
                            Currency.format(change < 0 ? 0 : change),
                            bold: true,
                            size: 12,
                            color: Colors.green.shade700,
                          ),
                        ] else
                          _kv(
                            'Status',
                            'Menunggu scan',
                            bold: true,
                            size: 12,
                            color: Colors.orange.shade700,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('BATAL', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed:
                            _busy ? null : () => _doPay(printAfter: false),
                        child: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text((isQris || _method == 'card')
                                    ? 'BAYAR + CETAK'
                                    : 'BAYAR',
                                    style: const TextStyle(fontSize: 11)),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: (_busy || isQris || _method == 'card')
                            ? null
                            : () => _doPay(printAfter: true),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('BAYAR + CETAK',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
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

  Widget _buildQrisContent(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final qris = settings.qrisBytes;
    if (qris == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(6),
          color: Colors.orange.withValues(alpha: 0.08),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            const Text(
              'QRIS belum diupload',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Silakan scan QRIS fisik di toko, atau upload gambar QRIS di Info Toko.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          child: Image.memory(
            qris,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
        if (settings.qrisMerchantName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            settings.qrisMerchantName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Total: ${Currency.format(widget.total)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 2),
        const Text(
          'Pastikan notifikasi pembayaran sudah masuk sebelum konfirmasi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCardContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(6),
        color: Colors.blue.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          const Icon(Icons.credit_card, color: Colors.blue, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Gesek / tap kartu di EDC',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Konfirmasi setelah EDC menampilkan transaksi berhasil.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value,
      {bool bold = false, double size = 12, Color? color}) {
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
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(label, style: const TextStyle(fontSize: 10)),
      onPressed: () => setState(() => _paid.text = value.toStringAsFixed(0)),
    );
  }
}
