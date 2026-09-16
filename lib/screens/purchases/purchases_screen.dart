import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../models/purchase.dart';
import '../../state/store_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class PurchasesScreen extends StatefulWidget {
  final int initialTabIndex;

  const PurchasesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '10');
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedProductId;
  PaymentStatus _selectedStatus = PaymentStatus.paid;
  String _selectedPaymentMethod = 'Cash';

  static const List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _supplierController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onProductSelected(Product product) {
    setState(() {
      _selectedProductId = product.id;
      _priceController.text = product.purchasePrice.toStringAsFixed(2);
    });
  }

  void _submitPurchase(StoreProvider store) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product to purchase'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final supplier = _supplierController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim();

    final purchase = store.createPurchase(
      supplierName: supplier,
      productId: _selectedProductId!,
      quantity: qty,
      purchasePrice: price,
      paymentStatus: _selectedStatus,
      paymentMethod: _selectedPaymentMethod,
      notes: notes.isNotEmpty ? notes : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Purchase recorded! Added $qty units of ${purchase.productName} to stock.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Reset form
    setState(() {
      _supplierController.clear();
      _qtyController.text = '10';
      _priceController.clear();
      _notesController.clear();
      _selectedProductId = null;
      _selectedStatus = PaymentStatus.paid;
      _selectedPaymentMethod = 'Cash';
    });

    _tabController.animateTo(1); // Switch to history tab
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProviderScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_shopping_cart, size: 18),
                  SizedBox(width: 8),
                  Text('Record Purchase'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 8),
                  Text('History (${store.purchases.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewPurchaseView(store),
          _buildPurchaseHistoryView(store),
        ],
      ),
    );
  }

  // ==================== NEW PURCHASE VIEW ====================

  Widget _buildNewPurchaseView(StoreProvider store) {
    final products = store.products;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final unitPrice = double.tryParse(_priceController.text) ?? 0.0;
    final totalAmount = qty * unitPrice;

    Product? selectedProduct;
    if (_selectedProductId != null) {
      selectedProduct = store.getProductById(_selectedProductId!);
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Supplier Name
          TextFormField(
            controller: _supplierController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Supplier / Vendor Name *',
              hintText: 'e.g. Supplier / Distributor Name',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter supplier name';
              }
              return null;
            },
          ),
          if (store.purchases.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: store.purchases
                    .map((p) => p.supplierName.trim())
                    .toSet()
                    .where((s) => s.isNotEmpty)
                    .map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(s.split(' ').first, style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => _supplierController.text = s),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Select Product
          DropdownButtonFormField<String>(
            value: _selectedProductId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Product *',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            hint: const Text('Choose product to restock'),
            items: products.map((p) {
              return DropdownMenuItem(
                value: p.id,
                child: Text(
                  '${p.name} (Stock: ${p.stockQuantity} ${p.unit})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final prod = store.getProductById(val);
                if (prod != null) _onProductSelected(prod);
              }
            },
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please select a product';
              }
              return null;
            },
          ),
          if (selectedProduct != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Current Stock: ${selectedProduct.stockQuantity} ${selectedProduct.unit} • Normal Selling: ${Formatters.currency(selectedProduct.sellingPrice)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Quantity and Purchase Price Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Quantity *',
                    prefixIcon: const Icon(Icons.numbers),
                    suffixText: selectedProduct?.unit ?? 'pcs',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter quantity';
                    final parsed = int.tryParse(val);
                    if (parsed == null || parsed <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price *',
                    prefixText: '₹ ',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter price';
                    final parsed = double.tryParse(val);
                    if (parsed == null || parsed <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Calculation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Purchase Amount', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      Formatters.currency(totalAmount),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.warning),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$qty ${selectedProduct?.unit ?? "units"} Stock',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Status
          const Text('Payment Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Paid')),
                  selected: _selectedStatus == PaymentStatus.paid,
                  onSelected: (_) => setState(() => _selectedStatus = PaymentStatus.paid),
                  selectedColor: AppColors.success.withOpacity(0.15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Pending')),
                  selected: _selectedStatus == PaymentStatus.pending,
                  onSelected: (_) => setState(() => _selectedStatus = PaymentStatus.pending),
                  selectedColor: AppColors.error.withOpacity(0.15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Partial')),
                  selected: _selectedStatus == PaymentStatus.partial,
                  onSelected: (_) => setState(() => _selectedStatus = PaymentStatus.partial),
                  selectedColor: AppColors.warning.withOpacity(0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Method (if Paid or Partial)
          if (_selectedStatus != PaymentStatus.pending) ...[
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.payment),
              ),
              items: _paymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes / Invoice / Batch # (Optional)',
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Save Purchase Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _submitPurchase(store),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Record Purchase & Increase Stock', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ==================== PURCHASE HISTORY VIEW ====================

  Widget _buildPurchaseHistoryView(StoreProvider store) {
    final purchases = store.purchases;
    final totalSpent = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);

    return Column(
      children: [
        // Summary bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Total Orders', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('${purchases.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(height: 24, width: 1, color: AppColors.border),
                Column(
                  children: [
                    const Text('Total Inventory Spent', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(totalSpent),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Purchases List
        Expanded(
          child: purchases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_outlined, size: 56, color: AppColors.textMuted.withOpacity(0.4)),
                      const SizedBox(height: 10),
                      const Text(
                        'No purchase records found',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                  itemCount: purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final p = purchases[i];

                    Color statusColor;
                    Color statusBg;
                    switch (p.paymentStatus) {
                      case PaymentStatus.paid:
                        statusColor = AppColors.success;
                        statusBg = AppColors.successBg;
                        break;
                      case PaymentStatus.pending:
                        statusColor = AppColors.error;
                        statusBg = AppColors.errorBg;
                        break;
                      case PaymentStatus.partial:
                        statusColor = AppColors.warning;
                        statusBg = AppColors.warningBg;
                        break;
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.purchaseOrderNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.paymentStatus.displayName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  Formatters.currency(p.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.productName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Supplier: ${p.supplierName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${p.quantity} units @ ${Formatters.currency(p.purchasePrice)} • ${p.paymentMethod}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                Text(
                                  Formatters.date(p.dateTime),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
