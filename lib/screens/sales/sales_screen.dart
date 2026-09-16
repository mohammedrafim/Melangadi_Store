import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../state/store_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'sale_receipt_dialog.dart';

class SalesScreen extends StatefulWidget {
  final int initialTabIndex;

  const SalesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cart state for New Sale
  final Map<String, int> _cart = {}; // productId -> quantity
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
  String _productSearchQuery = '';

  // History state
  String _historyTimeFilter = 'All'; // 'Today', 'All'
  String _historyPaymentFilter = 'All'; // 'All', 'Cash', 'UPI', 'Credit'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _notesController.clear();
      _selectedPaymentMethod = PaymentMethod.cash;
    });
  }

  void _addToCart(Product product) {
    final currentQty = _cart[product.id] ?? 0;
    if (currentQty >= product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add more. Only ${product.stockQuantity} ${product.unit} available in stock!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _cart[product.id] = currentQty + 1;
    });
  }

  void _removeFromCart(String productId) {
    final currentQty = _cart[productId] ?? 0;
    if (currentQty <= 1) {
      setState(() {
        _cart.remove(productId);
      });
    } else {
      setState(() {
        _cart[productId] = currentQty - 1;
      });
    }
  }

  void _deleteFromCart(String productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  void _completeSale(StoreProvider store) {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Please add products to sell.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate credit payment customer name
    if (_selectedPaymentMethod == PaymentMethod.credit && _customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer name is required for Credit (Khata) sales.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Build SaleItems list
    final List<SaleItem> items = [];
    for (final entry in _cart.entries) {
      final product = store.getProductById(entry.key);
      if (product != null) {
        if (entry.value > product.stockQuantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Insufficient stock for "${product.name}". Available: ${product.stockQuantity}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        items.add(SaleItem(
          productId: product.id,
          productName: product.name,
          quantity: entry.value,
          unitPrice: product.sellingPrice,
          unitPurchasePrice: product.purchasePrice,
        ));
      }
    }

    final newSale = store.createSale(
      items: items,
      paymentMethod: _selectedPaymentMethod,
      customerName: _customerNameController.text.trim().isNotEmpty ? _customerNameController.text.trim() : null,
      customerPhone: _customerPhoneController.text.trim().isNotEmpty ? _customerPhoneController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    _clearCart();

    // Show receipt dialog
    SaleReceiptDialog.show(
      context,
      sale: newSale,
      onNewSale: () {
        _tabController.animateTo(0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProviderScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.point_of_sale, size: 18),
                  const SizedBox(width: 8),
                  const Text('New Sale (POS)'),
                  if (_cart.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_cart.values.fold(0, (s, q) => s + q)}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 18),
                  const SizedBox(width: 8),
                  Text('History (${store.sales.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewSaleView(store),
          _buildSalesHistoryView(store),
        ],
      ),
    );
  }

  // ==================== NEW SALE (POS) VIEW ====================

  Widget _buildNewSaleView(StoreProvider store) {
    final availableProducts = store.products.where((p) {
      return _productSearchQuery.isEmpty ||
          p.name.toLowerCase().contains(_productSearchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_productSearchQuery.toLowerCase());
    }).toList();

    // Calculate live cart total
    double cartTotal = 0.0;
    int cartCount = 0;
    for (final entry in _cart.entries) {
      final p = store.getProductById(entry.key);
      if (p != null) {
        cartTotal += p.sellingPrice * entry.value;
        cartCount += entry.value;
      }
    }

    return Column(
      children: [
        // Cart Summary Header & Items
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Search stationery product section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _productSearchController,
                        onChanged: (val) => setState(() => _productSearchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search product to add...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _productSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _productSearchController.clear();
                                    setState(() => _productSearchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Quick Pick Horizontal List
                      SizedBox(
                        height: 94,
                        child: availableProducts.isEmpty
                            ? const Center(
                                child: Text('No products matching search', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: availableProducts.length,
                                itemBuilder: (ctx, i) {
                                  final p = availableProducts[i];
                                  final inCart = _cart[p.id] ?? 0;
                                  final isOut = p.stockQuantity <= 0;

                                  return GestureDetector(
                                    onTap: isOut ? null : () => _addToCart(p),
                                    child: Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isOut
                                            ? AppColors.scaffoldBg
                                            : (inCart > 0 ? AppColors.primary.withOpacity(0.06) : AppColors.cardBg),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: inCart > 0 ? AppColors.primary : AppColors.border,
                                          width: inCart > 0 ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isOut ? AppColors.textMuted : AppColors.textPrimary,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                Formatters.currency(p.sellingPrice),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOut ? AppColors.textMuted : AppColors.primary,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isOut
                                                      ? AppColors.errorBg
                                                      : (inCart > 0 ? AppColors.primary : AppColors.scaffoldBg),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isOut ? 'Out' : (inCart > 0 ? '✓ $inCart' : '+ Stock ${p.stockQuantity}'),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isOut
                                                        ? AppColors.error
                                                        : (inCart > 0 ? Colors.white : AppColors.textSecondary),
                                                  ),
                                                ),
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
                      const SizedBox(height: 8),
                      const Divider(),
                    ],
                  ),
                ),
              ),

              // Cart Section Title & Clear button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Cart Items',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          if (_cart.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$cartCount units',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                      if (_cart.isNotEmpty)
                        TextButton.icon(
                          onPressed: _clearCart,
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                          label: const Text('Clear Cart', style: TextStyle(fontSize: 12, color: AppColors.error)),
                        ),
                    ],
                  ),
                ),
              ),

              // Cart Items List
              if (_cart.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 54, color: AppColors.textMuted.withOpacity(0.4)),
                        const SizedBox(height: 10),
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap products above or search to add them to this sale bill',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final productId = _cart.keys.elementAt(i);
                      final qty = _cart[productId]!;
                      final product = store.getProductById(productId);
                      if (product == null) return const SizedBox.shrink();

                      final itemTotal = qty * product.sellingPrice;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${Formatters.currency(product.sellingPrice)} each • Avail: ${product.stockQuantity}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Stepper
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _removeFromCart(productId),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Icon(Icons.remove, size: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: qty < product.stockQuantity ? () => _addToCart(product) : null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Icon(
                                            Icons.add,
                                            size: 16,
                                            color: qty < product.stockQuantity ? AppColors.primary : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Item Total
                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    Formatters.currency(itemTotal),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                  onPressed: () => _deleteFromCart(productId),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _cart.length,
                  ),
                ),

              // Customer & Payment Details (if cart has items)
              if (_cart.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Payment Method',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        // Payment Method Choice Chips
                        Row(
                          children: [
                            _buildPaymentMethodOption(PaymentMethod.cash, Icons.payments_outlined, 'Cash'),
                            const SizedBox(width: 8),
                            _buildPaymentMethodOption(PaymentMethod.upi, Icons.qr_code_2_rounded, 'UPI'),
                            const SizedBox(width: 8),
                            _buildPaymentMethodOption(PaymentMethod.credit, Icons.menu_book_outlined, 'Credit (Khata)'),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Customer Details
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _customerNameController,
                                decoration: InputDecoration(
                                  labelText: _selectedPaymentMethod == PaymentMethod.credit
                                      ? 'Customer Name *'
                                      : 'Customer Name (Optional)',
                                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _customerPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes / Remarks (Optional)',
                            prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                        ),
                        const SizedBox(height: 100), // spacing for bottom checkout bar
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Bottom Checkout Bar
        if (_cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total ($cartCount items)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        Formatters.currency(cartTotal),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _completeSale(store),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text('Complete Sale (${_selectedPaymentMethod.displayName})'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method, IconData icon, String label) {
    final isSelected = _selectedPaymentMethod == method;
    Color color = AppColors.primary;
    if (method == PaymentMethod.cash) color = AppColors.success;
    if (method == PaymentMethod.upi) color = AppColors.purple;
    if (method == PaymentMethod.credit) color = AppColors.warning;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SALES HISTORY VIEW ====================

  Widget _buildSalesHistoryView(StoreProvider store) {
    final now = DateTime.now();

    final filtered = store.sales.where((s) {
      if (_historyTimeFilter == 'Today') {
        if (!(s.dateTime.year == now.year && s.dateTime.month == now.month && s.dateTime.day == now.day)) {
          return false;
        }
      }
      if (_historyPaymentFilter == 'Cash' && s.paymentMethod != PaymentMethod.cash) return false;
      if (_historyPaymentFilter == 'UPI' && s.paymentMethod != PaymentMethod.upi) return false;
      if (_historyPaymentFilter == 'Credit' && s.paymentMethod != PaymentMethod.credit) return false;

      return true;
    }).toList();

    final totalRevenue = filtered.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalProfit = filtered.fold(0.0, (sum, s) => sum + s.totalProfit);

    return Column(
      children: [
        // Summary & Filters Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Orders', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('${filtered.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(height: 24, width: 1, color: AppColors.border),
                    Column(
                      children: [
                        const Text('Total Revenue', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.currency(totalRevenue),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: AppColors.border),
                    Column(
                      children: [
                        const Text('Total Profit', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '+${Formatters.currency(totalProfit)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Time'),
                    selected: _historyTimeFilter == 'All',
                    onSelected: (_) => setState(() => _historyTimeFilter = 'All'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Today Only'),
                    selected: _historyTimeFilter == 'Today',
                    onSelected: (_) => setState(() => _historyTimeFilter = 'Today'),
                  ),
                  const SizedBox(width: 12),
                  Container(height: 20, width: 1, color: AppColors.border),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Cash', 'UPI', 'Credit'].map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(m),
                              selected: _historyPaymentFilter == m,
                              onSelected: (_) => setState(() => _historyPaymentFilter = m),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Sales List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted.withOpacity(0.4)),
                      const SizedBox(height: 10),
                      const Text(
                        'No sales records found',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final sale = filtered[i];

                    Color badgeColor;
                    Color badgeBg;
                    switch (sale.paymentMethod) {
                      case PaymentMethod.cash:
                        badgeColor = AppColors.success;
                        badgeBg = AppColors.successBg;
                        break;
                      case PaymentMethod.upi:
                        badgeColor = AppColors.purple;
                        badgeBg = AppColors.purpleBg;
                        break;
                      case PaymentMethod.credit:
                        badgeColor = AppColors.warning;
                        badgeBg = AppColors.warningBg;
                        break;
                    }

                    final itemsSummary = sale.items
                        .map((item) => '${item.quantity}x ${item.productName}')
                        .join(', ');

                    return InkWell(
                      onTap: () => SaleReceiptDialog.show(context, sale: sale),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
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
                                        sale.invoiceNumber,
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
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          sale.paymentMethod.displayName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    Formatters.currency(sale.totalAmount),
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
                                itemsSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sale.customerName != null && sale.customerName!.isNotEmpty
                                        ? 'Customer: ${sale.customerName}'
                                        : Formatters.date(sale.dateTime),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  Text(
                                    'Profit: +${Formatters.currency(sale.totalProfit)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
