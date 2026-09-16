import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';

class StoreProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Sale> _sales = [];
  List<Purchase> _purchases = [];
  double _cashInHand = 0.0;
  bool _isLoading = true;

  StoreProvider() {
    _initData();
  }

  // Getters
  bool get isLoading => _isLoading;
  List<Product> get products => List.unmodifiable(_products);
  List<Sale> get sales => List.unmodifiable(_sales);
  List<Purchase> get purchases => List.unmodifiable(_purchases);
  double get cashInHand => _cashInHand;

  // ==================== DASHBOARD METRICS ====================

  /// Checks if two dates are the same calendar day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Today's Total Sales Amount
  double get todaySalesAmount {
    final now = DateTime.now();
    return _sales
        .where((s) => _isSameDay(s.dateTime, now))
        .fold(0.0, (sum, s) => sum + s.totalAmount);
  }

  /// Today's Total Purchases Amount
  double get todayPurchasesAmount {
    final now = DateTime.now();
    return _purchases
        .where((p) => _isSameDay(p.dateTime, now))
        .fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  /// Today's Realized Profit (Revenue - Cost of Goods Sold)
  double get todayProfit {
    final now = DateTime.now();
    return _sales
        .where((s) => _isSameDay(s.dateTime, now))
        .fold(0.0, (sum, s) => sum + s.totalProfit);
  }

  /// Overall Lifetime Profit
  double get overallProfit {
    return _sales.fold(0.0, (sum, s) => sum + s.totalProfit);
  }

  /// Total unique products available in catalog
  int get totalAvailableProducts => _products.length;

  /// Total unit quantity of all products currently in stock
  int get totalStockUnits => _products.fold(0, (sum, p) => sum + p.stockQuantity);

  /// Low stock products (quantity > 0 and <= minStockThreshold, or out of stock)
  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock || p.isOutOfStock).toList();

  /// Today's sales list (newest first)
  List<Sale> get todaySales {
    final now = DateTime.now();
    return _sales.where((s) => _isSameDay(s.dateTime, now)).toList();
  }

  /// Today's purchases list (newest first)
  List<Purchase> get todayPurchases {
    final now = DateTime.now();
    return _purchases.where((p) => _isSameDay(p.dateTime, now)).toList();
  }

  /// Recent sales (last 10)
  List<Sale> get recentSales => _sales.take(10).toList();

  /// Recent purchases (last 10)
  List<Purchase> get recentPurchases => _purchases.take(10).toList();

  // ==================== PRODUCT ACTIONS ====================

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProduct(Product product) async {
    _products.insert(0, product);
    await DatabaseService.instance.saveProduct(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product updated) async {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      await DatabaseService.instance.saveProduct(updated);
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    await DatabaseService.instance.deleteProduct(id);
    notifyListeners();
  }

  Future<void> adjustStock(String productId, int delta) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index];
      final newQuantity = (current.stockQuantity + delta).clamp(0, 999999);
      final updated = current.copyWith(stockQuantity: newQuantity);
      _products[index] = updated;
      await DatabaseService.instance.saveProduct(updated);
      notifyListeners();
    }
  }

  // ==================== SALES ACTIONS ====================

  /// Creates and records a new Sale, automatically deducting stock and updating cash
  Sale createSale({
    required List<SaleItem> items,
    required PaymentMethod paymentMethod,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('Sale must contain at least one item');
    }

    // 1. Verify and deduct stock for each item
    for (final item in items) {
      final productIndex = _products.indexWhere((p) => p.id == item.productId);
      if (productIndex != -1) {
        final current = _products[productIndex];
        final updatedStock = (current.stockQuantity - item.quantity).clamp(0, 999999);
        final updated = current.copyWith(stockQuantity: updatedStock);
        _products[productIndex] = updated;
        DatabaseService.instance.saveProduct(updated);
      }
    }

    // 2. Build new Sale object
    final newSale = Sale(
      id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: Formatters.generateInvoiceCode('INV', _sales.length + 101),
      dateTime: DateTime.now(),
      items: items,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
    );

    // 3. Update cash if paid in cash
    if (paymentMethod == PaymentMethod.cash) {
      _cashInHand += newSale.totalAmount;
      DatabaseService.instance.setCashInHand(_cashInHand);
    }

    _sales.insert(0, newSale);
    DatabaseService.instance.saveSale(newSale);
    notifyListeners();
    return newSale;
  }

  // ==================== PURCHASE ACTIONS ====================

  /// Records a purchase from supplier, increasing stock and adjusting cash if paid in cash
  Purchase createPurchase({
    required String supplierName,
    required String productId,
    required int quantity,
    required double purchasePrice,
    required PaymentStatus paymentStatus,
    String paymentMethod = 'Cash',
    String? notes,
  }) {
    if (quantity <= 0) {
      throw ArgumentError('Purchase quantity must be greater than zero');
    }

    final productIndex = _products.indexWhere((p) => p.id == productId);
    final productName = productIndex != -1 ? _products[productIndex].name : 'Product';

    // 1. Automatically increase stock quantity for the purchased product
    if (productIndex != -1) {
      final current = _products[productIndex];
      final updated = current.copyWith(
        stockQuantity: current.stockQuantity + quantity,
        purchasePrice: purchasePrice, // Update latest purchase cost
      );
      _products[productIndex] = updated;
      DatabaseService.instance.saveProduct(updated);
    }

    final totalAmount = quantity * purchasePrice;

    // 2. Build new Purchase object
    final newPurchase = Purchase(
      id: 'purch_${DateTime.now().millisecondsSinceEpoch}',
      purchaseOrderNumber: Formatters.generateInvoiceCode('PO', _purchases.length + 201),
      dateTime: DateTime.now(),
      supplierName: supplierName.trim(),
      productId: productId,
      productName: productName,
      quantity: quantity,
      purchasePrice: purchasePrice,
      totalAmount: totalAmount,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    // 3. If paid in cash, deduct from Cash in Hand
    if (paymentStatus == PaymentStatus.paid && paymentMethod == 'Cash') {
      _cashInHand = (_cashInHand - totalAmount).clamp(0.0, double.infinity);
      DatabaseService.instance.setCashInHand(_cashInHand);
    }

    _purchases.insert(0, newPurchase);
    DatabaseService.instance.savePurchase(newPurchase);
    notifyListeners();
    return newPurchase;
  }

  /// Adjust Cash in Hand directly (e.g. initial cash, bank deposit, owner injection)
  Future<void> updateCashInHand(double newAmount) async {
    _cashInHand = newAmount;
    await DatabaseService.instance.setCashInHand(_cashInHand);
    notifyListeners();
  }

  // ==================== HIVE DATABASE SYNC ====================

  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseService.instance.init();
      _products = DatabaseService.instance.getProducts();
      _sales = DatabaseService.instance.getSales();
      _purchases = DatabaseService.instance.getPurchases();
      _cashInHand = DatabaseService.instance.getCashInHand();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading Hive database: $e');
      }
      _products = [];
      _sales = [];
      _purchases = [];
      _cashInHand = 0.0;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Reset and clear all store data in Hive database
  Future<void> clearAllData() async {
    try {
      await DatabaseService.instance.clearAll();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing Hive database: $e');
      }
    }
    _products = [];
    _sales = [];
    _purchases = [];
    _cashInHand = 0.0;
    notifyListeners();
  }
}

class StoreProviderScope extends InheritedNotifier<StoreProvider> {
  const StoreProviderScope({
    super.key,
    required StoreProvider notifier,
    required super.child,
  }) : super(notifier: notifier);

  static StoreProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreProviderScope>();
    assert(scope != null, 'No StoreProviderScope found in context');
    return scope!.notifier!;
  }
}
