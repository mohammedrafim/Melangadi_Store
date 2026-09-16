import 'package:flutter/material.dart';
import '../../models/sale.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class SaleReceiptDialog extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onNewSale;

  const SaleReceiptDialog({
    super.key,
    required this.sale,
    this.onNewSale,
  });

  static Future<void> show(
    BuildContext context, {
    required Sale sale,
    VoidCallback? onNewSale,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SaleReceiptDialog(
        sale: sale,
        onNewSale: onNewSale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color methodColor;
    Color methodBg;
    IconData methodIcon;

    switch (sale.paymentMethod) {
      case PaymentMethod.cash:
        methodColor = AppColors.success;
        methodBg = AppColors.successBg;
        methodIcon = Icons.payments_outlined;
        break;
      case PaymentMethod.upi:
        methodColor = AppColors.purple;
        methodBg = AppColors.purpleBg;
        methodIcon = Icons.qr_code_2_rounded;
        break;
      case PaymentMethod.credit:
        methodColor = AppColors.warning;
        methodBg = AppColors.warningBg;
        methodIcon = Icons.menu_book_outlined;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 36),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Sale Completed!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const Center(
              child: Text(
                'Melangadi Store',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Invoice Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sale.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
                Text(
                  Formatters.date(sale.dateTime),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (sale.customerName != null && sale.customerName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Customer: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    sale.customerName!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Payment badge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: methodBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(methodIcon, size: 14, color: methodColor),
                    const SizedBox(width: 4),
                    Text(
                      'Paid via ${sale.paymentMethod.displayName}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: methodColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Items List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sale.items.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (ctx, i) {
                  final item = sale.items[i];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.quantity} × ${Formatters.currency(item.unitPrice)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(item.totalAmount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items (${sale.totalItemCount})',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  Formatters.currency(sale.totalAmount),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profit on this sale',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  '+${Formatters.currency(sale.totalProfit)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNewSale?.call();
                    },
                    child: const Text('New Sale'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
