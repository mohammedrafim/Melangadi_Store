import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../state/store_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../products/product_form_dialog.dart';
import '../sales/sale_receipt_dialog.dart';
import '../../services/preferences_service.dart';
import 'backup_restore_dialog.dart';
import 'preferences_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex) onNavigateToTab;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showOverallProfit = false; // Toggle between Today's Profit and Lifetime Profit

  void _showCashAdjustDialog(BuildContext context, StoreProvider store) {
    final controller = TextEditingController(text: store.cashInHand.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Cash in Hand'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter actual cash counted in the cash register / drawer:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cash Amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(controller.text.trim());
              if (newAmount != null && newAmount >= 0) {
                store.updateCashInHand(newAmount);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cash in Hand updated to ${Formatters.currency(newAmount)}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, StoreProvider store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Store Data?'),
        content: const Text(
          'This will permanently delete all products, stock quantities, sales records, and purchases, resetting the entire store to a clean state. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              store.clearAllData();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All products and records have been cleared.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProviderScope.of(context);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Melangadi Store',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  Formatters.shortDate(now),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppColors.textSecondary),
            tooltip: 'Adjust Cash in Hand',
            onPressed: () => _showCashAdjustDialog(context, store),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (val) {
              if (val == 'adjust_cash') {
                _showCashAdjustDialog(context, store);
              } else if (val == 'backup_restore') {
                BackupRestoreDialog.show(context);
              } else if (val == 'preferences') {
                PreferencesDialog.show(context).then((_) => setState(() {}));
              } else if (val == 'clear_all') {
                _showClearDataDialog(context, store);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'adjust_cash',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Adjust Cash in Hand'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'backup_restore',
                child: Row(
                  children: [
                    Icon(Icons.sync_alt, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Backup & Restore Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'preferences',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Store Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Clear All Data', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.add_shopping_cart,
                    label: 'New Sale',
                    color: AppColors.success,
                    onTap: () => widget.onNavigateToTab(1), // Sales Tab
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.local_shipping_outlined,
                    label: 'New Purchase',
                    color: AppColors.warning,
                    onTap: () => widget.onNavigateToTab(2), // Purchase Tab
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.add_box_outlined,
                    label: 'Add Product',
                    color: AppColors.primaryLight,
                    onTap: () => ProductFormDialog.show(
                      context,
                      onSave: (p) => store.addProduct(p),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Top Financial Overview Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showOverallProfit = !_showOverallProfit),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _showOverallProfit ? 'Showing: Overall' : 'Showing: Today',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Today's Total Sales Card (Primary Green)
            _buildMetricCard(
              title: "Today's Total Sales",
              amount: Formatters.currency(store.todaySalesAmount),
              subtitle: '${store.todaySales.length} transactions today',
              icon: Icons.payments_rounded,
              iconColor: AppColors.success,
              bgColor: AppColors.successBg,
              borderColor: AppColors.success.withOpacity(0.3),
              onTap: () => widget.onNavigateToTab(1),
            ),
            const SizedBox(height: 12),

            // 2-Card Grid: Today's Purchases & Cash in Hand
            Row(
              children: [
                Expanded(
                  child: _buildSmallMetricCard(
                    title: "Today's Purchases",
                    amount: Formatters.currency(store.todayPurchasesAmount),
                    subtitle: '${store.todayPurchases.length} orders today',
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppColors.warning,
                    bgColor: AppColors.warningBg,
                    onTap: () => widget.onNavigateToTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallMetricCard(
                    title: 'Cash in Hand',
                    amount: Formatters.currency(store.cashInHand),
                    subtitle: 'Drawer Balance',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.08),
                    onTap: () => _showCashAdjustDialog(context, store),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2-Card Grid: Total Available Products & Profit
            Row(
              children: [
                Expanded(
                  child: _buildSmallMetricCard(
                    title: 'Available Products',
                    amount: '${store.totalAvailableProducts}',
                    subtitle: '${store.totalStockUnits} total units in stock',
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.info,
                    bgColor: AppColors.infoBg,
                    onTap: () => widget.onNavigateToTab(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallMetricCard(
                    title: _showOverallProfit ? 'Overall Profit' : "Today's Profit",
                    amount: Formatters.currency(_showOverallProfit ? store.overallProfit : store.todayProfit),
                    subtitle: _showOverallProfit ? 'Lifetime realized' : 'Earned today',
                    icon: Icons.trending_up,
                    iconColor: AppColors.success,
                    bgColor: AppColors.successBg,
                    onTap: () => setState(() => _showOverallProfit = !_showOverallProfit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Low Stock Warning Banner
            if (store.lowStockProducts.isNotEmpty) ...[
              _buildLowStockSection(context, store),
              const SizedBox(height: 20),
            ],

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Sales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateToTab(1),
                  child: const Text('View All', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (store.sales.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No sales recorded yet', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              ...store.recentSales.take(4).map((sale) => _buildRecentSaleItem(context, sale)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: iconColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Icon(icon, color: iconColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: iconColor),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection(BuildContext context, StoreProvider store) {
    final lowStockItems = store.lowStockProducts;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Low Stock Alert (${lowStockItems.length} items)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
              ),
              const Spacer(),
              InkWell(
                onTap: () => widget.onNavigateToTab(2), // Jump to purchase
                child: const Text(
                  'Reorder Now →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: lowStockItems.map((p) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        p.name.length > 20 ? '${p.name.substring(0, 18)}...' : p.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${p.stockQuantity} ${p.unit}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSaleItem(BuildContext context, Sale sale) {
    Color methodColor = AppColors.success;
    if (sale.paymentMethod == PaymentMethod.upi) methodColor = AppColors.purple;
    if (sale.paymentMethod == PaymentMethod.credit) methodColor = AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => SaleReceiptDialog.show(context, sale: sale),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: methodColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sale.paymentMethod == PaymentMethod.cash
                      ? Icons.payments_outlined
                      : (sale.paymentMethod == PaymentMethod.upi ? Icons.qr_code_2 : Icons.menu_book),
                  color: methodColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.customerName ?? sale.invoiceNumber,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Formatters.date(sale.dateTime),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(sale.totalAmount),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '+${Formatters.currency(sale.totalProfit)} profit',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
