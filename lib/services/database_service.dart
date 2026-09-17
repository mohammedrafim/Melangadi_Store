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

  Box<Map>? _productsBox;
  Box<Map>? _salesBox;
  Box<Map>? _purchasesBox;
  Box? _settingsBox;

  Future<void>? _initFuture;
  bool get isInitialized => _productsBox != null && _productsBox!.isOpen;

  /// Initialize Hive NoSQL Database and open boxes safely
  Future<void> init([String? subDir]) {
    _initFuture ??= _doInit(subDir);
    return _initFuture!;
  }

  Future<void> _doInit([String? subDir]) async {
    try {
      await Hive.initFlutter(subDir);
    } catch (_) {
      // Fallback for headless testing or non-Flutter CLI environments
      final testDir = subDir != null ? Directory(subDir) : Directory.systemTemp.createTempSync('melangadi_hive_');
      Hive.init(testDir.path);
    }

    _productsBox = await Hive.openBox<Map>(productsBoxName);
    _salesBox = await Hive.openBox<Map>(salesBoxName);
    _purchasesBox = await Hive.openBox<Map>(purchasesBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

    if (kDebugMode) {
      print('==============================================');
      print('📦 HIVE DATABASE CONNECTED & INITIALIZED!');
      print('📁 Storage Path: ${_productsBox?.path}');
      print('📊 Products: ${_productsBox?.length ?? 0}, Sales: ${_salesBox?.length ?? 0}, Purchases: ${_purchasesBox?.length ?? 0}');
      print('==============================================');
    }
  }

  // ================= PRODUCTS =================

  List<Product> getProducts() {
    final box = _productsBox;
    if (box == null) return [];

    final list = <Product>[];
    for (final raw in box.values) {
      try {
        final map = Map<String, dynamic>.from(raw);
        list.add(Product.fromMap(map));
      } catch (e) {
        if (kDebugMode) print('Error parsing product from Hive: $e');
      }
    }
    return list.reversed.toList();
  }

  Future<void> saveProduct(Product product) async {
    await init();
    await _productsBox!.put(product.id, product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await init();
    await _productsBox!.delete(id);
  }

  // ================= SALES =================

  List<Sale> getSales() {
    final box = _salesBox;
    if (box == null) return [];

    final list = <Sale>[];
    for (final raw in box.values) {
      try {
        final map = Map<String, dynamic>.from(raw);
        list.add(Sale.fromMap(map));
      } catch (e) {
        if (kDebugMode) print('Error parsing sale from Hive: $e');
      }
    }
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<void> saveSale(Sale sale) async {
    await init();
    await _salesBox!.put(sale.id, sale.toMap());
  }

  // ================= PURCHASES =================

  List<Purchase> getPurchases() {
    final box = _purchasesBox;
    if (box == null) return [];

    final list = <Purchase>[];
    for (final raw in box.values) {
      try {
        final map = Map<String, dynamic>.from(raw);
        list.add(Purchase.fromMap(map));
      } catch (e) {
        if (kDebugMode) print('Error parsing purchase from Hive: $e');
      }
    }
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<void> savePurchase(Purchase purchase) async {
    await init();
    await _purchasesBox!.put(purchase.id, purchase.toMap());
  }

  // ================= SETTINGS & CASH =================

  double getCashInHand() {
    final box = _settingsBox;
    if (box == null) return 0.0;

    final val = box.get('cashInHand', defaultValue: 0.0);
    if (val is num) {
      return val.toDouble();
    }
    return 0.0;
  }

  Future<void> setCashInHand(double amount) async {
    await init();
    await _settingsBox!.put('cashInHand', amount);
  }

  // ================= BACKUP & RESTORE =================

  /// Export entire database into a JSON-compatible Map
  Future<Map<String, dynamic>> exportBackupData() async {
    await init();

    final productsRaw = _productsBox!.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final purchasesRaw = _purchasesBox!.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final salesRaw = _salesBox!.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final cashInHand = getCashInHand();

    return {
      'app': 'Melangadi Store',
      'version': '1.0.0',
      'backupTimestamp': DateTime.now().toIso8601String(),
      'cashInHand': cashInHand,
      'products': productsRaw,
      'purchases': purchasesRaw,
      'sales': salesRaw,
    };
  }

  /// Restore database from a backup Map
  Future<void> importBackupData(Map<String, dynamic> backupData) async {
    await init();

    // 1. Clear existing data
    await clearAll();

    // 2. Restore cash in hand
    if (backupData.containsKey('cashInHand')) {
      final cash = (backupData['cashInHand'] as num?)?.toDouble() ?? 0.0;
      await setCashInHand(cash);
    }

    // 3. Restore products
    if (backupData['products'] is List) {
      final products = backupData['products'] as List;
      for (final p in products) {
        if (p is Map && p['id'] != null) {
          await _productsBox!.put(p['id'].toString(), Map<String, dynamic>.from(p));
        }
      }
    }

    // 4. Restore purchases
    if (backupData['purchases'] is List) {
      final purchases = backupData['purchases'] as List;
      for (final purch in purchases) {
        if (purch is Map && purch['id'] != null) {
          await _purchasesBox!.put(purch['id'].toString(), Map<String, dynamic>.from(purch));
        }
      }
    }

    // 5. Restore sales
    if (backupData['sales'] is List) {
      final sales = backupData['sales'] as List;
      for (final s in sales) {
        if (s is Map && s['id'] != null) {
          await _salesBox!.put(s['id'].toString(), Map<String, dynamic>.from(s));
        }
      }
    }
  }

  // ================= CLEAR DATA =================

  Future<void> clearAll() async {
    await init();
    await _productsBox?.clear();
    await _salesBox?.clear();
    await _purchasesBox?.clear();
    await _settingsBox?.clear();
  }
}
