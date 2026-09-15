import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';
import '../widgets/app_appbar.dart';

class ProductFormView extends StatefulWidget {
  final Product? existing;
  const ProductFormView({super.key, this.existing});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _stock;
  late final TextEditingController _unit;
  int? _categoryId;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _price = TextEditingController(
      text: p == null ? '' : p.price.toStringAsFixed(0),
    );
    _cost = TextEditingController(
      text: p == null ? '' : p.costPrice.toStringAsFixed(0),
    );
    _stock = TextEditingController(
      text: p == null ? '' : p.stock.toStringAsFixed(0),
    );
    _unit = TextEditingController(text: p?.unit ?? 'pcs');
    _categoryId = p?.categoryId;
    _active = p?.isActive ?? true;
    Future.microtask(() => context.read<CategoryViewModel>().load());
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _barcode.dispose();
    _price.dispose();
    _cost.dispose();
    _stock.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk wajib diisi.')),
      );
      return;
    }
    final price = double.tryParse(_price.text.trim()) ?? 0;
    final cost = double.tryParse(_cost.text.trim()) ?? 0;
    final stock = double.tryParse(_stock.text.trim()) ?? 0;

    final p = Product(
      id: widget.existing?.id,
      categoryId: _categoryId,
      sku: _sku.text.trim(),
      barcode: _barcode.text.trim(),
      name: _name.text.trim(),
      price: price,
      costPrice: cost,
      stock: stock,
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      isActive: _active,
    );

    final vm = context.read<ProductViewModel>();
    if (widget.existing == null) {
      await vm.add(p);
    } else {
      await vm.edit(p);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryViewModel>().items;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    const denseInput = InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: TextStyle(fontSize: 12),
    );

    return Scaffold(
      appBar: AppAppBar(
        title: widget.existing == null ? 'Tambah Produk' : 'Edit Produk',
        subtitle: 'Isi data produk',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: bottomInset + 16,
            ),
            children: [
              TextField(
                controller: _name,
                decoration: denseInput.copyWith(labelText: 'Nama produk *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _sku,
                decoration: denseInput.copyWith(labelText: 'SKU (opsional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _barcode,
                decoration:
                    denseInput.copyWith(labelText: 'Barcode (opsional)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                decoration: denseInput.copyWith(labelText: 'Kategori'),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: [
                  const DropdownMenuItem(value: null, child: Text('- Tanpa -')),
                  ...cats.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: denseInput.copyWith(labelText: 'Harga jual'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: denseInput.copyWith(labelText: 'Harga modal'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: denseInput.copyWith(labelText: 'Stok'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _unit,
                      decoration: denseInput.copyWith(labelText: 'Satuan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title:
                    const Text('Produk aktif', style: TextStyle(fontSize: 12)),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('SIMPAN',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
