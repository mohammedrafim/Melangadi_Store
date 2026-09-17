import 'dart:convert';
import 'database_service.dart';
import 'preferences_service.dart';

class BackupSummary {
  final int productsCount;
  final int purchasesCount;
  final int salesCount;
  final double cashInHand;
  final DateTime timestamp;

  BackupSummary({
    required this.productsCount,
    required this.purchasesCount,
    required this.salesCount,
    required this.cashInHand,
    required this.timestamp,
  });
}

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  /// Export local Hive database into a formatted JSON string
  Future<String> exportBackupToJsonString() async {
    final data = await DatabaseService.instance.exportBackupData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    // Record last backup date in SharedPreferences
    await PreferencesService.instance.setLastBackupDate(DateTime.now().toIso8601String());

    return jsonStr;
  }

  /// Parse and inspect backup content without applying it
  BackupSummary inspectBackup(String jsonContent) {
    final decoded = json.decode(jsonContent.trim());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup: Root JSON must be an object.');
    }

    final products = decoded['products'];
    final purchases = decoded['purchases'];
    final sales = decoded['sales'];

    if (products is! List || purchases is! List || sales is! List) {
      throw const FormatException('Invalid backup: Missing products, purchases, or sales data.');
    }

    DateTime timestamp = DateTime.now();
    if (decoded['backupTimestamp'] != null) {
      try {
        timestamp = DateTime.parse(decoded['backupTimestamp'].toString());
      } catch (_) {}
    }

    final cashInHand = (decoded['cashInHand'] as num?)?.toDouble() ?? 0.0;

    return BackupSummary(
      productsCount: products.length,
      purchasesCount: purchases.length,
      salesCount: sales.length,
      cashInHand: cashInHand,
      timestamp: timestamp,
    );
  }

  /// Restore database from JSON string
  Future<BackupSummary> restoreFromJsonString(String jsonContent) async {
    final summary = inspectBackup(jsonContent);
    final decoded = Map<String, dynamic>.from(json.decode(jsonContent.trim()) as Map);

    await DatabaseService.instance.importBackupData(decoded);
    return summary;
  }
}
