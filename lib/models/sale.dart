enum PaymentMethod {
  cash,
  upi,
  credit;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'upi':
        return PaymentMethod.upi;
      case 'credit':
        return PaymentMethod.credit;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }
}

class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double unitPurchasePrice;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitPurchasePrice,
  });

  double get totalAmount => quantity * unitPrice;
  double get totalCost => quantity * unitPurchasePrice;
  double get profit => totalAmount - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitPurchasePrice': unitPurchasePrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      unitPurchasePrice: (map['unitPurchasePrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Sale {
  final String id;
  final String invoiceNumber;
  final DateTime dateTime;
  final List<SaleItem> items;
  final PaymentMethod paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String? notes;

  const Sale({
    required this.id,
    required this.invoiceNumber,
    required this.dateTime,
    required this.items,
    required this.paymentMethod,
    this.customerName,
    this.customerPhone,
    this.notes,
  });

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.totalAmount);
  double get totalCost => items.fold(0.0, (sum, item) => sum + item.totalCost);
  double get totalProfit => totalAmount - totalCost;
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'dateTime': dateTime.toIso8601String(),
      'items': items.map((e) => e.toMap()).toList(),
      'paymentMethod': paymentMethod.name,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      invoiceNumber: map['invoiceNumber'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      items: (map['items'] as List<dynamic>)
          .map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String),
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
