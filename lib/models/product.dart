class Product {
  final int? id;
  final int? categoryId;
  final String sku;
  final String barcode;
  final String name;
  final double price;
  final double costPrice;
  final double stock;
  final String unit;
  final bool isActive;

  const Product({
    this.id,
    this.categoryId,
    this.sku = '',
    this.barcode = '',
    required this.name,
    required this.price,
    this.costPrice = 0,
    this.stock = 0,
    this.unit = 'pcs',
    this.isActive = true,
  });

  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int?,
        sku: (map['sku'] as String?) ?? '',
        barcode: (map['barcode'] as String?) ?? '',
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
        stock: (map['stock'] as num?)?.toDouble() ?? 0,
        unit: (map['unit'] as String?) ?? 'pcs',
        isActive: ((map['is_active'] as int?) ?? 1) == 1,
      );

  Map<String, Object?> toMap() => {
        'category_id': categoryId,
        'sku': sku,
        'barcode': barcode,
        'name': name,
        'price': price,
        'cost_price': costPrice,
        'stock': stock,
        'unit': unit,
        'is_active': isActive ? 1 : 0,
      };

  Map<String, Object?> toInsertMap() => {
        if (id != null) 'id': id,
        ...toMap(),
      };
}
