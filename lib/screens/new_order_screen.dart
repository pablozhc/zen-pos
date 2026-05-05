import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/primary_button.dart';
import '../viewmodels/products_viewmodel.dart';
import '../utils/currency_formatter.dart';

class NewOrderScreen extends StatefulWidget {
  final int? preselectedTableNumber;

  const NewOrderScreen({
    super.key,
    this.preselectedTableNumber,
  });

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedTableNumber;
  final Map<String, int> _cart = {}; // productId -> quantity
  late TabController _tabController;
  String _selectedCategoryId = 'food';

  @override
  void initState() {
    super.initState();
    _selectedTableNumber = widget.preselectedTableNumber;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productsVM = context.read<ProductsViewModel>();
    _tabController = TabController(
      length: productsVM.categories.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategoryId = productsVM.categories[_tabController.index].id;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsVM = context.watch<ProductsViewModel>();
    final selectedCategory = productsVM.getCategoryById(_selectedCategoryId);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Table selection
            _buildTableSelector(),

            // Category tabs
            _buildCategoryTabs(productsVM),

            // Products list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // All products in category
                    Text(
                      'VŠE ${selectedCategory?.title.toUpperCase() ?? ''}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildAllProducts(productsVM),
                  ],
                ),
              ),
            ),

            // Cart summary & submit button
            if (_cart.isNotEmpty) _buildCartSummary(productsVM),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      color: AppColors.background,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'NOVÁ OBJEDNÁVKA',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STŮL:',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: List.generate(10, (index) {
              final tableNum = index + 1;
              final isSelected = _selectedTableNumber == tableNum;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTableNumber = tableNum;
                  });
                },
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(CornerRadius.sm),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$tableNum',
                      style: AppTypography.h4.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ProductsViewModel productsVM) {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: _tabController,
        isScrollable: productsVM.categories.length > 4,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.labelMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: productsVM.categories.map((category) {
          return Tab(text: category.title);
        }).toList(),
      ),
    );
  }

  Widget _buildAllProducts(ProductsViewModel productsVM) {
    final products = productsVM.getProductsByCategory(_selectedCategoryId);
    return Column(
      children: products.map((product) {
        final quantity = _cart[product.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: _buildProductRow(product, quantity),
        );
      }).toList(),
    );
  }

  Widget _buildProductRow(Product product, int quantity) {
    return InkWell(
      onTap: () => _addToCart(product),
      child: Container(
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(CornerRadius.md),
        ),
        child: Row(
          children: [
            Text(
              product.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: AppTypography.monoMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (quantity > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(CornerRadius.full),
                ),
                child: Text(
                  '$quantity',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              )
            else
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(ProductsViewModel productsVM) {
    final total = _calculateTotal(productsVM);
    final itemCount = _cart.values.fold(0, (sum, qty) => sum + qty);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KOŠÍK ($itemCount položek)',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.format(total),
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          PrimaryButton(
            title: _selectedTableNumber != null
                ? 'ODESLAT NA STŮL $_selectedTableNumber'
                : 'VYBERTE STŮL',
            onPressed: _selectedTableNumber != null ? () => _submitOrder(productsVM) : null,
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    });
  }

  double _calculateTotal(ProductsViewModel productsVM) {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = productsVM.products.firstWhere(
        (p) => p.id == entry.key,
      );
      total += product.price * entry.value;
    }
    return total;
  }

  void _submitOrder(ProductsViewModel productsVM) {
    if (_selectedTableNumber == null) return;

    // Create order items
    final items = <OrderItem>[];
    for (final entry in _cart.entries) {
      final product = productsVM.products.firstWhere(
        (p) => p.id == entry.key,
      );
      items.add(OrderItem(
        id: const Uuid().v4(),
        product: product,
        quantity: entry.value,
      ));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Objednávka odeslána na stůl $_selectedTableNumber',
          style: AppTypography.bodyLarge.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}
