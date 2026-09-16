class Product {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final int stockQuantity;
  final int minStockThreshold;
  final String unit;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.minStockThreshold = 10,
    this.unit = 'pcs',
  });

  bool get isLowStock => stockQuantity > 0 && stockQuantity <= minStockThreshold;
  bool get isOutOfStock => stockQuantity <= 0;
  double get profitMargin => sellingPrice - purchasePrice;
  double get profitMarginPercent => purchasePrice > 0 ? ((sellingPrice - purchasePrice) / purchasePrice) * 100 : 0;
  double get totalStockValue => stockQuantity * purchasePrice;
  double get totalRetailValue => stockQuantity * sellingPrice;

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? stockQuantity,
    int? minStockThreshold,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'minStockThreshold': minStockThreshold,
      'unit': unit,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'General',
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      stockQuantity: (map['stockQuantity'] as num).toInt(),
      minStockThreshold: (map['minStockThreshold'] as num?)?.toInt() ?? 10,
      unit: map['unit'] as String? ?? 'pcs',
    );
  }
}
