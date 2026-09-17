import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/backup_service.dart';
import '../../services/preferences_service.dart';
import '../../state/store_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const BackupRestoreDialog(),
    );
  }

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Backup Tab state
  String _backupJson = '';
  bool _isGeneratingBackup = false;

  // Restore Tab state
  final TextEditingController _restoreJsonController = TextEditingController();
  BackupSummary? _inspectedBackup;
  String? _restoreError;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateBackup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _restoreJsonController.dispose();
    super.dispose();
  }

  Future<void> _generateBackup() async {
    setState(() {
      _isGeneratingBackup = true;
    });
    try {
      final jsonStr = await BackupService.instance.exportBackupToJsonString();
      if (mounted) {
        setState(() {
          _backupJson = jsonStr;
          _isGeneratingBackup = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingBackup = false;
        });
      }
    }
  }

  void _copyBackupToClipboard() {
    if (_backupJson.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _backupJson));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup JSON copied to clipboard!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _inspectRestoreJson() {
    final text = _restoreJsonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _restoreError = 'Please paste backup JSON data first.';
        _inspectedBackup = null;
      });
      return;
    }

    try {
      final summary = BackupService.instance.inspectBackup(text);
      setState(() {
        _inspectedBackup = summary;
        _restoreError = null;
      });
    } catch (e) {
      setState(() {
        _restoreError = e.toString().replaceFirst('FormatException: ', '');
        _inspectedBackup = null;
      });
    }
  }

  Future<void> _performRestore(StoreProvider store) async {
    if (_inspectedBackup == null) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      final summary = await store.restoreFromBackupJson(_restoreJsonController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored successfully! (${summary.productsCount} products, ${summary.salesCount} sales, ${summary.purchasesCount} purchases)',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _restoreError = 'Failed to restore: $e';
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProviderScope.of(context);
    final lastBackup = PreferencesService.instance.lastBackupDate;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 620),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12, top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sync_alt, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Local Backup & Restore',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 6),
                      Text('Backup (Export)'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload, size: 18),
                      SizedBox(width: 6),
                      Text('Restore (Import)'),
                    ],
                  ),
                ),
              ],
            ),

            // Tab Bar Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBackupTab(store, lastBackup),
                  _buildRestoreTab(store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupTab(StoreProvider store, String? lastBackup) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Offline local backup description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Offline Data Export',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastBackup != null
                            ? 'Last backup: ${Formatters.date(DateTime.parse(lastBackup))}'
                            : 'All data is stored locally on this device in Hive database.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Store summary cards
          Row(
            children: [
              _buildMiniMetric('Products', '${store.products.length}'),
              const SizedBox(width: 8),
              _buildMiniMetric('Sales', '${store.sales.length}'),
              const SizedBox(width: 8),
              _buildMiniMetric('Purchases', '${store.purchases.length}'),
            ],
          ),
          const SizedBox(height: 14),

          // JSON Content Preview
          const Text(
            'Backup JSON Payload:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            height: 180,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: _isGeneratingBackup
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: SelectableText(
                      _backupJson,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generateBackup,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: _backupJson.isNotEmpty ? _copyBackupToClipboard : null,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy JSON Backup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreTab(StoreProvider store) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warning Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Restoring from a backup will replace current products, purchases, sales, and cash balance with the backup contents.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Paste Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paste Backup JSON Data:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _restoreJsonController.text = data!.text!;
                    _inspectRestoreJson();
                  }
                },
                icon: const Icon(Icons.paste, size: 16),
                label: const Text('Paste', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _restoreJsonController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Paste JSON content here...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (_) => _inspectRestoreJson(),
          ),

          // Error message
          if (_restoreError != null) ...[
            const SizedBox(height: 8),
            Text(
              _restoreError!,
              style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ],

          // Inspection Summary
          if (_inspectedBackup != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Valid Backup Found:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                  const SizedBox(height: 6),
                  Text('• Products: ${_inspectedBackup!.productsCount} items'),
                  Text('• Sales: ${_inspectedBackup!.salesCount} records'),
                  Text('• Purchases: ${_inspectedBackup!.purchasesCount} records'),
                  Text('• Cash in Hand: ${Formatters.currency(_inspectedBackup!.cashInHand)}'),
                  Text('• Timestamp: ${Formatters.date(_inspectedBackup!.timestamp)}'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Restore Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: (_inspectedBackup != null && !_isRestoring)
                ? () => _showConfirmRestoreDialog(context, store)
                : null,
            icon: _isRestoring
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.restore),
            label: const Text('Confirm & Restore Data'),
          ),
        ],
      ),
    );
  }

  void _showConfirmRestoreDialog(BuildContext context, StoreProvider store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Overwrite All Data?'),
        content: Text(
          'This will replace your current store records with ${_inspectedBackup!.productsCount} products, ${_inspectedBackup!.salesCount} sales, and ${_inspectedBackup!.purchasesCount} purchases. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              _performRestore(store);
            },
            child: const Text('Yes, Overwrite & Restore'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
