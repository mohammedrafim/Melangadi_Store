import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/purchase.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static const String productsBoxName = 'melangadi_products';
  static const String salesBoxName = 'melangadi_sales';
  static const String purchasesBoxName = 'melangadi_purchases';
  static const String settingsBoxName = 'melangadi_settings';

  late Box<Map> _productsBox;
  late Box<Map> _salesBox;
  late Box<Map> _purchasesBox;
  late Box _settingsBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Hive NoSQL Database and open boxes
  Future<void> init([String? subDir]) async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter(subDir);
    } catch (_) {
      // Fallback for headless testing environments
      Hive.init(Directory.current.path);
    }

    _productsBox = await Hive.openBox<Map>(productsBoxName);
    _salesBox = await Hive.openBox<Map>(salesBoxName);
    _purchasesBox = await Hive.openBox<Map>(purchasesBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

    _isInitialized = true;

    if (kDebugMode) {
      print('==============================================');
      print('📦 HIVE DATABASE CONNECTED & INITIALIZED!');
      print('📁 Storage Path: ${_productsBox.path}');
      print('📊 Products: ${_productsBox.length}, Sales: ${_salesBox.length}, Purchases: ${_purchasesBox.length}');
      print('==============================================');
    }
  }

  // ================= PRODUCTS =================

  List<Product> getProducts() {
    final list = <Product>[];
    for (final raw in _productsBox.values) {
      try {
        final map = Map<String, dynamic>.from(raw as Map);
        list.add(Product.fromMap(map));
      } catch (e) {
        // Skip invalid records
      }
    }
    return list.reversed.toList();
  }

  Future<void> saveProduct(Product product) async {
    await _productsBox.put(product.id, product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _productsBox.delete(id);
  }

  // ================= SALES =================

  List<Sale> getSales() {
    final list = <Sale>[];
    for (final raw in _salesBox.values) {
      try {
        final map = Map<String, dynamic>.from(raw as Map);
        list.add(Sale.fromMap(map));
      } catch (e) {
        // Skip invalid records
      }
    }
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<void> saveSale(Sale sale) async {
    await _salesBox.put(sale.id, sale.toMap());
  }

  // ================= PURCHASES =================

  List<Purchase> getPurchases() {
    final list = <Purchase>[];
    for (final raw in _purchasesBox.values) {
      try {
        final map = Map<String, dynamic>.from(raw as Map);
        list.add(Purchase.fromMap(map));
      } catch (e) {
        // Skip invalid records
      }
    }
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<void> savePurchase(Purchase purchase) async {
    await _purchasesBox.put(purchase.id, purchase.toMap());
  }

  // ================= SETTINGS & CASH =================

  double getCashInHand() {
    final val = _settingsBox.get('cashInHand', defaultValue: 0.0);
    if (val is num) {
      return val.toDouble();
    }
    return 0.0;
  }

  Future<void> setCashInHand(double amount) async {
    await _settingsBox.put('cashInHand', amount);
  }

  // ================= CLEAR DATA =================

  Future<void> clearAll() async {
    await _productsBox.clear();
    await _salesBox.clear();
    await _purchasesBox.clear();
    await _settingsBox.clear();
  }
}
