import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';

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
    // ignore: unused_local_variable
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Tambah Produk' : 'Edit Produk'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nama produk *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sku,
            decoration: const InputDecoration(
              labelText: 'SKU (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _barcode,
            decoration: const InputDecoration(
              labelText: 'Barcode (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('- Tanpa -')),
              ...cats.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga jual',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cost,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga modal',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stok',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: const Text('Produk aktif'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('SIMPAN'),
            ),
          ),
        ],
      ),
    );
  }
}
