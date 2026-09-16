enum PaymentStatus {
  paid,
  pending,
  partial;

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partial';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'partial':
        return PaymentStatus.partial;
      case 'paid':
      default:
        return PaymentStatus.paid;
    }
  }
}

class Purchase {
  final String id;
  final String purchaseOrderNumber;
  final DateTime dateTime;
  final String supplierName;
  final String productId;
  final String productName;
  final int quantity;
  final double purchasePrice;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final String paymentMethod; // Cash, UPI, Bank Transfer
  final String? notes;

  const Purchase({
    required this.id,
    required this.purchaseOrderNumber,
    required this.dateTime,
    required this.supplierName,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod = 'Cash',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseOrderNumber': purchaseOrderNumber,
      'dateTime': dateTime.toIso8601String(),
      'supplierName': supplierName,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as String,
      purchaseOrderNumber: map['purchaseOrderNumber'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      supplierName: map['supplierName'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paymentStatus: PaymentStatus.fromString(map['paymentStatus'] as String),
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      notes: map['notes'] as String?,
    );
  }
}
