import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melangadi_store/models/product.dart';
import 'package:melangadi_store/models/sale.dart';
import 'package:melangadi_store/models/purchase.dart';
import 'package:melangadi_store/services/database_service.dart';
import 'package:melangadi_store/services/preferences_service.dart';
import 'package:melangadi_store/services/backup_service.dart';
import 'package:melangadi_store/state/store_provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.instance.init();

    tempDir = Directory.systemTemp.createTempSync('melangadi_test_');
    await DatabaseService.instance.init(tempDir.path);
  });

  tearDownAll(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('StoreProvider & Hive Database Unit Tests', () {
    late StoreProvider store;

    setUp(() async {
      store = StoreProvider();
      await store.initialized;
      await store.clearAllData();
    });

    test('Initializes with clean empty state', () {
      expect(store.products.isEmpty, isTrue);
      expect(store.totalAvailableProducts, 0);
      expect(store.cashInHand, 0.0);
    });

    test('Add, update, and delete product using local Hive database', () async {
      const testProduct = Product(
        id: 'test_p_1',
        name: 'Camlin Exam Gel Pen',
        category: 'Pens & Writing',
        purchasePrice: 15.0,
        sellingPrice: 25.0,
        stockQuantity: 50,
        minStockThreshold: 10,
        unit: 'pcs',
      );

      // Add
      await store.addProduct(testProduct);
      expect(store.products.length, 1);
      expect(store.getProductById('test_p_1')?.name, 'Camlin Exam Gel Pen');

      // Update
      final updated = testProduct.copyWith(sellingPrice: 30.0, stockQuantity: 45);
      await store.updateProduct(updated);
      expect(store.getProductById('test_p_1')?.sellingPrice, 30.0);
      expect(store.getProductById('test_p_1')?.stockQuantity, 45);

      // Adjust stock
      await store.adjustStock('test_p_1', 5);
      expect(store.getProductById('test_p_1')?.stockQuantity, 50);
      await store.adjustStock('test_p_1', -10);
      expect(store.getProductById('test_p_1')?.stockQuantity, 40);

      // Delete
      await store.deleteProduct('test_p_1');
      expect(store.products.length, 0);
      expect(store.getProductById('test_p_1'), isNull);
    });

    test('Sale automatically deducts stock and increases Cash in Hand on cash sale', () async {
      const testProduct = Product(
        id: 'test_p_1',
        name: 'Camlin Exam Gel Pen',
        category: 'Pens & Writing',
        purchasePrice: 15.0,
        sellingPrice: 25.0,
        stockQuantity: 50,
        minStockThreshold: 10,
        unit: 'pcs',
      );
      await store.addProduct(testProduct);
      await store.updateCashInHand(100.0);

      final initialCash = store.cashInHand;
      const sellQty = 2;

      final sale = store.createSale(
        items: [
          SaleItem(
            productId: testProduct.id,
            productName: testProduct.name,
            quantity: sellQty,
            unitPrice: testProduct.sellingPrice,
            unitPurchasePrice: testProduct.purchasePrice,
          ),
        ],
        paymentMethod: PaymentMethod.cash,
        customerName: 'Test Buyer',
      );

      final updatedProduct = store.getProductById(testProduct.id)!;
      expect(updatedProduct.stockQuantity, 50 - sellQty);
      expect(store.cashInHand, initialCash + sale.totalAmount);
      expect(sale.totalAmount, sellQty * testProduct.sellingPrice);
      expect(sale.totalProfit, sellQty * (testProduct.sellingPrice - testProduct.purchasePrice));
    });

    test('Sale via UPI or Credit does not alter Cash in Hand directly', () async {
      const testProduct = Product(
        id: 'test_p_2',
        name: 'A4 Notebook',
        category: 'Notebooks',
        purchasePrice: 30.0,
        sellingPrice: 50.0,
        stockQuantity: 20,
        minStockThreshold: 5,
        unit: 'pcs',
      );
      await store.addProduct(testProduct);
      await store.updateCashInHand(200.0);
      final initialCash = store.cashInHand;

      store.createSale(
        items: [
          SaleItem(
            productId: testProduct.id,
            productName: testProduct.name,
            quantity: 1,
            unitPrice: testProduct.sellingPrice,
            unitPurchasePrice: testProduct.purchasePrice,
          ),
        ],
        paymentMethod: PaymentMethod.upi,
      );

      expect(store.cashInHand, initialCash);
    });

    test('Purchase automatically increases stock and deducts Cash in Hand when paid in Cash', () async {
      const testProduct = Product(
        id: 'test_p_3',
        name: 'Marker Pen',
        category: 'Pens & Writing',
        purchasePrice: 20.0,
        sellingPrice: 35.0,
        stockQuantity: 10,
        minStockThreshold: 5,
        unit: 'pcs',
      );
      await store.addProduct(testProduct);
      await store.updateCashInHand(500.0);
      final initialCash = store.cashInHand;

      const purchaseQty = 10;
      const costPrice = 20.0;

      final purchase = store.createPurchase(
        supplierName: 'Navneet Wholesale',
        productId: testProduct.id,
        quantity: purchaseQty,
        purchasePrice: costPrice,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: 'Cash',
      );

      final updatedProduct = store.getProductById(testProduct.id)!;
      expect(updatedProduct.stockQuantity, 10 + purchaseQty);
      expect(purchase.totalAmount, purchaseQty * costPrice);
      expect(store.cashInHand, initialCash - purchase.totalAmount);
    });

    test('Dashboard KPIs calculate today sales, purchases, and profit dynamically', () async {
      const testProduct = Product(
        id: 'test_p_4',
        name: 'Stapler',
        category: 'Desk Essentials',
        purchasePrice: 40.0,
        sellingPrice: 60.0,
        stockQuantity: 15,
        minStockThreshold: 5,
        unit: 'pcs',
      );
      await store.addProduct(testProduct);

      store.createSale(
        items: [
          SaleItem(
            productId: testProduct.id,
            productName: testProduct.name,
            quantity: 2,
            unitPrice: testProduct.sellingPrice,
            unitPurchasePrice: testProduct.purchasePrice,
          ),
        ],
        paymentMethod: PaymentMethod.cash,
      );

      store.createPurchase(
        supplierName: 'Vendor',
        productId: testProduct.id,
        quantity: 5,
        purchasePrice: 40.0,
        paymentStatus: PaymentStatus.paid,
      );

      expect(store.todaySalesAmount, 120.0);
      expect(store.todayPurchasesAmount, 200.0);
      expect(store.todayProfit, 40.0);
      expect(store.overallProfit, 40.0);
      expect(store.totalAvailableProducts, 1);
      // initial 15 - 2 sold + 5 purchased = 18 units
      expect(store.totalStockUnits, 18);
    });

    test('Data persistence: reloads state from disk on app restart', () async {
      const testProduct = Product(
        id: 'p_persist_1',
        name: 'Geometry Box',
        category: 'Instruments',
        purchasePrice: 80.0,
        sellingPrice: 120.0,
        stockQuantity: 25,
        minStockThreshold: 5,
        unit: 'box',
      );
      await store.addProduct(testProduct);
      await store.updateCashInHand(350.0);

      store.createSale(
        items: [
          SaleItem(
            productId: testProduct.id,
            productName: testProduct.name,
            quantity: 3,
            unitPrice: 120.0,
            unitPurchasePrice: 80.0,
          ),
        ],
        paymentMethod: PaymentMethod.cash,
      );

      // Simulate app restart by creating a new StoreProvider instance
      final restartedStore = StoreProvider();
      await restartedStore.initialized;

      expect(restartedStore.products.length, 1);
      expect(restartedStore.products.first.name, 'Geometry Box');
      expect(restartedStore.products.first.stockQuantity, 22);
      expect(restartedStore.sales.length, 1);
      expect(restartedStore.sales.first.totalAmount, 360.0);
      expect(restartedStore.cashInHand, 350.0 + 360.0);
    });

    test('Backup and restore: export to JSON and restore into new state', () async {
      const testProduct = Product(
        id: 'p_backup_1',
        name: 'A4 Notebook 200 pgs',
        category: 'Notebooks',
        purchasePrice: 45.0,
        sellingPrice: 70.0,
        stockQuantity: 30,
        minStockThreshold: 5,
        unit: 'pcs',
      );
      await store.addProduct(testProduct);
      await store.updateCashInHand(1200.0);

      // Export backup
      final backupJson = await BackupService.instance.exportBackupToJsonString();
      expect(backupJson.contains('A4 Notebook 200 pgs'), isTrue);

      // Clear all
      await store.clearAllData();
      expect(store.products.isEmpty, isTrue);
      expect(store.cashInHand, 0.0);

      // Restore
      final summary = await store.restoreFromBackupJson(backupJson);
      expect(summary.productsCount, 1);
      expect(summary.cashInHand, 1200.0);
      expect(store.products.length, 1);
      expect(store.products.first.name, 'A4 Notebook 200 pgs');
      expect(store.cashInHand, 1200.0);
    });

    test('PreferencesService handles user preferences via SharedPreferences', () async {
      final prefs = PreferencesService.instance;
      await prefs.setCashierName('Rafi Store Manager');
      await prefs.setStoreName('Melangadi Stationery');
      await prefs.setLoggedIn(true);

      expect(prefs.cashierName, 'Rafi Store Manager');
      expect(prefs.storeName, 'Melangadi Stationery');
      expect(prefs.isLoggedIn, isTrue);
    });
  });
}
