import 'dart:io';
import 'package:hive/hive.dart';

void main() async {
  final home = Platform.environment['HOME'] ?? '';
  final candidateDirs = [
    '$home/.local/share/com.example.melangadi_store',
    '$home/.local/share/melangadi_store',
    Directory.current.path,
  ];

  String? dbDir;
  for (final dir in candidateDirs) {
    if (Directory(dir).existsSync()) {
      final hasHive = Directory(dir)
          .listSync()
          .any((e) => e.path.endsWith('.hive'));
      if (hasHive) {
        dbDir = dir;
        break;
      }
    }
  }

  // Fallback search in ~/.local/share
  if (dbDir == null) {
    final localShare = Directory('$home/.local/share');
    if (localShare.existsSync()) {
      try {
        for (final entity in localShare.listSync(recursive: true)) {
          if (entity.path.endsWith('melangadi_products.hive')) {
            dbDir = entity.parent.path;
            break;
          }
        }
      } catch (_) {}
    }
  }

  if (dbDir == null) {
    print('======================================================');
    print('⚠️  No Hive database files found yet.');
    print('Please launch the application first using:');
    print('   flutter run');
    print('and add a product or sale to generate the Hive boxes.');
    print('======================================================');
    return;
  }

  print('======================================================');
  print('📂 HIVE DATABASE DIRECTORY:');
  print('   $dbDir');
  print('======================================================\n');

  final dir = Directory(dbDir);
  print('📄 PHYSICAL .HIVE DATABASE BOXES:');
  for (final file in dir.listSync().where((e) => e.path.endsWith('.hive'))) {
    final stat = file.statSync();
    print('   • ${file.uri.pathSegments.last} (${stat.size} bytes, modified: ${stat.modified})');
  }
  print('');

  Hive.init(dbDir);

  final productsBox = await Hive.openBox<Map>('melangadi_products');
  final salesBox = await Hive.openBox<Map>('melangadi_sales');
  final purchasesBox = await Hive.openBox<Map>('melangadi_purchases');
  final settingsBox = await Hive.openBox('melangadi_settings');

  final cash = settingsBox.get('cashInHand', defaultValue: 0.0);
  print('💵 CASH IN HAND: ₹$cash\n');

  print('📦 PRODUCTS IN HIVE (${productsBox.length} items):');
  if (productsBox.isEmpty) {
    print('   (No products stored yet)');
  } else {
    for (final key in productsBox.keys) {
      final p = productsBox.get(key);
      print('   • [ID: $key] ${p?['name']}');
      print('     Category: ${p?['category']} | Stock: ${p?['stockQuantity']} ${p?['unit']}');
      print('     Cost: ₹${p?['purchasePrice']} | Selling: ₹${p?['sellingPrice']}');
      print('     --------------------------------------------------');
    }
  }
  print('');

  print('🛍️ SALES IN HIVE (${salesBox.length} invoices):');
  if (salesBox.isEmpty) {
    print('   (No sales recorded yet)');
  } else {
    for (final key in salesBox.keys) {
      final s = salesBox.get(key);
      final items = (s?['items'] as List?) ?? [];
      print('   • [Invoice: ${s?['invoiceNumber']}] Date: ${s?['dateTime']}');
      print('     Customer: ${s?['customerName'] ?? 'Walk-in'} | Total: ₹${s?['totalAmount']} | Method: ${s?['paymentMethod']}');
      for (final item in items) {
        print('       - ${item['productName']} (Qty: ${item['quantity']} × ₹${item['unitPrice']})');
      }
      print('     --------------------------------------------------');
    }
  }
  print('');

  print('📥 PURCHASES IN HIVE (${purchasesBox.length} orders):');
  if (purchasesBox.isEmpty) {
    print('   (No purchase orders recorded yet)');
  } else {
    for (final key in purchasesBox.keys) {
      final pr = purchasesBox.get(key);
      print('   • [Order: ${pr?['purchaseOrderNumber']}] Supplier: ${pr?['supplierName']}');
      print('     Product: ${pr?['productName']} (Qty: ${pr?['quantity']}) @ ₹${pr?['purchasePrice']}');
      print('     Total: ₹${pr?['totalAmount']} | Status: ${pr?['paymentStatus']}');
      print('     --------------------------------------------------');
    }
  }

  print('\n======================================================');
  print('✅ Hive database inspection complete.');
  print('======================================================');

  await Hive.close();
}
