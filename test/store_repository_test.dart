import 'package:flutter_test/flutter_test.dart';
import 'package:melangadi_store/models/product.dart';
import 'package:melangadi_store/models/sale.dart';
import 'package:melangadi_store/models/purchase.dart';
import 'package:melangadi_store/state/store_provider.dart';

void main() {
  group('StoreProvider Unit Tests', () {
    late StoreProvider store;

    setUp(() {
      store = StoreProvider();
      store.clearAllData();
    });

    test('Initializes with clean empty state', () {
      expect(store.products.isEmpty, isTrue);
      expect(store.totalAvailableProducts, 0);
      expect(store.cashInHand, 0.0);
    });

    test('Add, update, and delete product', () {
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
      store.addProduct(testProduct);
      expect(store.products.length, 1);
      expect(store.getProductById('test_p_1')?.name, 'Camlin Exam Gel Pen');

      // Update
      final updated = testProduct.copyWith(sellingPrice: 30.0, stockQuantity: 45);
      store.updateProduct(updated);
      expect(store.getProductById('test_p_1')?.sellingPrice, 30.0);
      expect(store.getProductById('test_p_1')?.stockQuantity, 45);

      // Adjust stock
      store.adjustStock('test_p_1', 5);
      expect(store.getProductById('test_p_1')?.stockQuantity, 50);
      store.adjustStock('test_p_1', -10);
      expect(store.getProductById('test_p_1')?.stockQuantity, 40);

      // Delete
      store.deleteProduct('test_p_1');
      expect(store.products.length, 0);
      expect(store.getProductById('test_p_1'), isNull);
    });

    test('Sale automatically deducts stock and increases Cash in Hand on cash sale', () {
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
      store.addProduct(testProduct);
      store.updateCashInHand(100.0);

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

    test('Sale via UPI or Credit does not alter Cash in Hand directly', () {
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
      store.addProduct(testProduct);
      store.updateCashInHand(200.0);
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

    test('Purchase automatically increases stock and deducts Cash in Hand when paid in Cash', () {
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
      store.addProduct(testProduct);
      store.updateCashInHand(500.0);
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

    test('Dashboard KPIs calculate today sales, purchases, and profit', () {
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
      store.addProduct(testProduct);

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
    });
  });
}
