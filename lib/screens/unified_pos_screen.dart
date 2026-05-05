import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/pos_navigation_viewmodel.dart';
import '../viewmodels/tables_viewmodel.dart';
import '../viewmodels/products_viewmodel.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../models/product_model.dart';
import '../models/payment_model.dart';
import '../models/table_model.dart';

import '../widgets/table_card.dart';
import '../widgets/order_item_row.dart';
import '../utils/currency_formatter.dart';
import '../services/printer_service.dart';
import 'payment_screen.dart';

class UnifiedPOSScreen extends StatelessWidget {
  const UnifiedPOSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => POSNavigationViewModel()),
      ],
      child: const _UnifiedPOSView(),
    );
  }
}

class _UnifiedPOSView extends StatelessWidget {
  const _UnifiedPOSView();

  @override
  Widget build(BuildContext context) {
    final navViewModel = context.watch<POSNavigationViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar (just title)
            _buildHeader(context, navViewModel),

            // Main content: Left 1/3 + Right 2/3
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel (1/3)
                  Expanded(
                    flex: 1,
                    child: _buildLeftPanel(context, navViewModel),
                  ),

                  // Divider
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),

                  // Right panel (2/3)
                  Expanded(
                    flex: 2,
                    child: _buildRightPanel(context, navViewModel),
                  ),
                ],
              ),
            ),

            // Bottom action bar with menu, back and payment buttons
            _buildBottomActionBar(context, navViewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, POSNavigationViewModel navViewModel) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      color: AppColors.background,
      child: Row(
        children: [
          // Title
          Expanded(
            child: Text(
              _getTitle(navViewModel),
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Additional actions can go here
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, POSNavigationViewModel navViewModel) {
    final tablesViewModel = context.watch<TablesViewModel>();
    final tableNumber = navViewModel.selectedTableNumber;
    final table = tableNumber != null ? tablesViewModel.getTableByNumber(tableNumber) : null;
    final hasItems = table?.currentOrder?.items.isNotEmpty ?? false;
    final isOnTablesList = navViewModel.state == POSNavigationState.tablesList;

    return Row(
      children: [
        // Left part (1/3) - menu or back button
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            color: AppColors.background,
            child: isOnTablesList
                ? ElevatedButton.icon(
                    onPressed: () => navViewModel.openMenu(),
                    icon: const Icon(Icons.menu),
                    label: Text(
                      'MENU',
                      style: AppTypography.labelLarge,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundTertiary,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => navViewModel.goBack(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(
                      'ZPĚT',
                      style: AppTypography.labelLarge,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundTertiary,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
          ),
        ),
        // Right part (2/3) - payment button or empty
        Expanded(
          flex: 2,
          child: hasItems
              ? Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  color: AppColors.backgroundSecondary,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (table != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(table: table),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: Text(
                      'ZAPLATIT',
                      style: AppTypography.labelLarge.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                )
              : Container(
                  color: AppColors.backgroundSecondary,
                ),
        ),
      ],
    );
  }

  String _getTitle(POSNavigationViewModel navViewModel) {
    switch (navViewModel.state) {
      case POSNavigationState.tablesList:
      case POSNavigationState.menu:
        return 'ZEN POS';
      case POSNavigationState.dailyReport:
        return 'DENNÍ REPORT';
      case POSNavigationState.history:
      case POSNavigationState.historyDetail:
        return 'HISTORIE';
      case POSNavigationState.manageCategories:
        return 'KATEGORIE';
      case POSNavigationState.manageProducts:
        return 'PRODUKTY';
      case POSNavigationState.tableDetail:
        return 'STŮL ${navViewModel.selectedTableNumber}';
      case POSNavigationState.categoryProducts:
        return navViewModel.selectedCategory?.title.toUpperCase() ?? '';
    }
  }

  Widget _buildLeftPanel(BuildContext context, POSNavigationViewModel navViewModel) {
    switch (navViewModel.state) {
      case POSNavigationState.tablesList:
        return _buildTablesList(context, navViewModel);
      case POSNavigationState.menu:
        return _buildMenuPanel(context, navViewModel);
      case POSNavigationState.dailyReport:
        return _buildDailyReportPanel(context);
      case POSNavigationState.history:
      case POSNavigationState.historyDetail:
        return _buildHistoryPanel(context, navViewModel);
      case POSNavigationState.manageCategories:
        return _buildManageCategoriesPanel(context);
      case POSNavigationState.manageProducts:
        return _buildManageProductsPanel(context);
      case POSNavigationState.tableDetail:
        return _buildCategoriesList(context, navViewModel);
      case POSNavigationState.categoryProducts:
        return _buildProductsList(context, navViewModel);
    }
  }

  Widget _buildRightPanel(BuildContext context, POSNavigationViewModel navViewModel) {
    switch (navViewModel.state) {
      case POSNavigationState.tablesList:
      case POSNavigationState.menu:
      case POSNavigationState.dailyReport:
      case POSNavigationState.history:
      case POSNavigationState.manageCategories:
      case POSNavigationState.manageProducts:
        return _buildPlaceholder();
      case POSNavigationState.historyDetail:
        return _buildPaymentDetail(context, navViewModel);
      case POSNavigationState.tableDetail:
      case POSNavigationState.categoryProducts:
        return _buildTableDetail(context, navViewModel);
    }
  }

  Widget _buildMenuPanel(BuildContext context, POSNavigationViewModel navViewModel) {
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Text(
            'NASTAVENÍ',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          _buildMenuItem(
            icon: Icons.print,
            title: 'Nastavení tiskárny',
            onTap: () => _showPrinterSettingsDialog(context),
          ),
          _buildMenuItem(
            icon: Icons.analytics,
            title: 'Denní report',
            onTap: () => navViewModel.openDailyReport(),
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Historie plateb',
            onTap: () => navViewModel.openHistory(),
          ),
          _buildMenuItem(
            icon: Icons.category,
            title: 'Kategorie',
            onTap: () => navViewModel.openManageCategories(),
          ),
          _buildMenuItem(
            icon: Icons.restaurant_menu,
            title: 'Produkty',
            onTap: () => navViewModel.openManageProducts(),
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Nastavení',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'O aplikaci',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  title: Text(
                    'ZEN POS',
                    style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    'Verze 1.0.0\n\nModerní pokladní systém pro restaurace a bary.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'ZAVŘÍT',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(CornerRadius.md),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 24),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReportPanel(BuildContext context) {
    final tablesViewModel = context.watch<TablesViewModel>();
    final todayPayments = tablesViewModel.todayPayments;
    final completedRevenue = tablesViewModel.todayCompletedRevenue;
    final openTabsTotal = tablesViewModel.openTabsTotal;
    final cardPayments = todayPayments.where((p) => p.method == PaymentMethod.card);
    final cashPayments = todayPayments.where((p) => p.method == PaymentMethod.cash);
    final totalTips = todayPayments.fold(0.0, (sum, p) => sum + p.tip);

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Text(
            'DENNÍ REPORT',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Completed revenue
          _buildReportCard(
            title: 'Provedené tržby',
            value: CurrencyFormatter.format(completedRevenue),
            icon: Icons.check_circle,
            color: AppColors.success,
          ),

          // Open tabs
          _buildReportCard(
            title: 'Otevřené účty',
            value: CurrencyFormatter.format(openTabsTotal),
            subtitle: '${tablesViewModel.activeTables.length} stolů',
            icon: Icons.table_restaurant,
            color: AppColors.primary,
          ),

          // Total
          _buildReportCard(
            title: 'Celkem (tržby + otevřené)',
            value: CurrencyFormatter.format(completedRevenue + openTabsTotal),
            icon: Icons.account_balance_wallet,
            color: AppColors.textPrimary,
          ),

          const SizedBox(height: Spacing.lg),
          Text(
            'DETAIL PLATEB',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Card payments
          _buildReportCard(
            title: 'Kartou',
            value: CurrencyFormatter.format(
              cardPayments.fold(0.0, (sum, p) => sum + p.totalWithTip),
            ),
            subtitle: '${cardPayments.length} plateb',
            icon: Icons.credit_card,
            color: AppColors.textSecondary,
          ),

          // Cash payments
          _buildReportCard(
            title: 'Hotovost',
            value: CurrencyFormatter.format(
              cashPayments.fold(0.0, (sum, p) => sum + p.totalWithTip),
            ),
            subtitle: '${cashPayments.length} plateb',
            icon: Icons.payments,
            color: AppColors.textSecondary,
          ),

          // Tips
          _buildReportCard(
            title: 'Spropitné celkem',
            value: CurrencyFormatter.format(totalTips),
            icon: Icons.volunteer_activism,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(CornerRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel(BuildContext context, POSNavigationViewModel navViewModel) {
    final tablesViewModel = context.watch<TablesViewModel>();
    final payments = tablesViewModel.todayPayments.reversed.toList();

    return Container(
      color: AppColors.background,
      child: payments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Žádné platby',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Dnes nebyly provedeny žádné platby',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                Text(
                  'DNEŠNÍ PLATBY',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                ...payments.map((payment) {
                  final isSelected = navViewModel.selectedPayment?.id == payment.id;
                  return InkWell(
                    onTap: () => navViewModel.selectPayment(payment),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: Spacing.sm),
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(CornerRadius.md),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            payment.method == PaymentMethod.card ? Icons.credit_card : Icons.payments,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stůl ${payment.tableNumber}',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${payment.timestamp.hour}:${payment.timestamp.minute.toString().padLeft(2, '0')} - ${payment.method.title}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(payment.totalWithTip),
                            style: AppTypography.h4.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildPaymentDetail(BuildContext context, POSNavigationViewModel navViewModel) {
    final payment = navViewModel.selectedPayment;
    if (payment == null) return _buildPlaceholder();

    return Container(
      color: AppColors.backgroundSecondary,
      child: Column(
        children: [
          // Payment header
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            color: AppColors.background,
            child: Column(
              children: [
                Text(
                  CurrencyFormatter.format(payment.totalWithTip),
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Stůl ${payment.tableNumber}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                Text(
                  'DETAIL PLATBY',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Spacing.md),

                _buildDetailRow(
                  'Typ platby',
                  payment.method == PaymentMethod.card ? 'Karta' : 'Hotovost',
                  payment.method == PaymentMethod.card ? Icons.credit_card : Icons.payments,
                ),
                _buildDetailRow(
                  'Částka',
                  CurrencyFormatter.format(payment.amount),
                  Icons.receipt,
                ),
                if (payment.tip > 0)
                  _buildDetailRow(
                    'Spropitné',
                    CurrencyFormatter.format(payment.tip),
                    Icons.volunteer_activism,
                  ),
                _buildDetailRow(
                  'Celkem',
                  CurrencyFormatter.format(payment.totalWithTip),
                  Icons.account_balance_wallet,
                ),
                _buildDetailRow(
                  'Čas',
                  '${payment.timestamp.hour}:${payment.timestamp.minute.toString().padLeft(2, '0')}:${payment.timestamp.second.toString().padLeft(2, '0')}',
                  Icons.access_time,
                ),
                _buildDetailRow(
                  'Datum',
                  '${payment.timestamp.day}.${payment.timestamp.month}.${payment.timestamp.year}',
                  Icons.calendar_today,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(CornerRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageCategoriesPanel(BuildContext context) {
    final productsViewModel = context.watch<ProductsViewModel>();
    final categories = productsViewModel.categories;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                Text(
                  'KATEGORIE',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                ...categories.map((cat) => Container(
                      margin: const EdgeInsets.only(bottom: Spacing.sm),
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(CornerRadius.md),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              cat.title,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${productsViewModel.getProductsByCategory(cat.id).length}',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: Spacing.sm),
                          IconButton(
                            onPressed: () => _showDeleteCategoryDialog(context, productsViewModel, cat),
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          // Add button
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            color: AppColors.background,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(context, productsViewModel),
              icon: const Icon(Icons.add),
              label: Text('PŘIDAT KATEGORII', style: AppTypography.labelLarge),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, ProductsViewModel vm) {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Nová kategorie', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Název kategorie'),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: emojiController,
              style: const TextStyle(fontSize: 28),
              decoration: const InputDecoration(hintText: 'Emoji (např. 🍕)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ZRUŠIT', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                vm.addCategory(
                  title: nameController.text,
                  emoji: emojiController.text.isEmpty ? '📁' : emojiController.text,
                );
                Navigator.pop(context);
              }
            },
            child: Text('PŘIDAT', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, ProductsViewModel vm, ProductCategory cat) {
    final productCount = vm.getProductsByCategory(cat.id).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Smazat kategorii?', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Kategorie "${cat.title}" a jejích $productCount produktů bude smazáno.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ZRUŠIT', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              vm.deleteCategory(cat.id);
              Navigator.pop(context);
            },
            child: Text('SMAZAT', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildManageProductsPanel(BuildContext context) {
    final productsViewModel = context.watch<ProductsViewModel>();
    final categories = productsViewModel.categories;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                ...categories.map((cat) {
                  final products = productsViewModel.getProductsByCategory(cat.id);
                  if (products.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm, top: Spacing.sm),
                        child: Text(
                          '${cat.emoji} ${cat.title.toUpperCase()}',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      ...products.map((product) => Container(
                            margin: const EdgeInsets.only(bottom: Spacing.sm),
                            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(CornerRadius.md),
                              border: Border.all(color: AppColors.border, width: 1),
                            ),
                            child: Row(
                              children: [
                                Text(product.emoji, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showEditPriceDialog(context, productsViewModel, product),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xxs),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundTertiary,
                                      borderRadius: BorderRadius.circular(CornerRadius.sm),
                                    ),
                                    child: Text(
                                      CurrencyFormatter.format(product.price),
                                      style: AppTypography.monoMedium.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacing.xs),
                                IconButton(
                                  onPressed: () {
                                    productsViewModel.deleteProduct(product.id);
                                  },
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          )),
                    ],
                  );
                }),
              ],
            ),
          ),
          // Add product button
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            color: AppColors.background,
            child: ElevatedButton.icon(
              onPressed: () => _showAddProductDialog(context, productsViewModel),
              icon: const Icon(Icons.add),
              label: Text('PŘIDAT PRODUKT', style: AppTypography.labelLarge),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, ProductsViewModel vm, Product product) {
    final controller = TextEditingController(text: product.price.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Upravit cenu', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${product.emoji} ${product.name}',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(suffixText: 'Kč'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ZRUŠIT', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                vm.updateProductPrice(product.id, newPrice);
                Navigator.pop(context);
              }
            },
            child: Text('ULOŽIT', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, ProductsViewModel vm) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final emojiController = TextEditingController();
    String? selectedCategoryId = vm.categories.isNotEmpty ? vm.categories.first.id : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Nový produkt', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Název produktu'),
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Cena', suffixText: 'Kč'),
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: emojiController,
                  style: const TextStyle(fontSize: 28),
                  decoration: const InputDecoration(hintText: 'Emoji (např. 🍕)'),
                ),
                const SizedBox(height: Spacing.md),
                // Category dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCategoryId,
                    isExpanded: true,
                    dropdownColor: AppColors.cardBackground,
                    underline: const SizedBox(),
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                    items: vm.categories.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text('${cat.emoji} ${cat.title}'),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ZRUŠIT', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final price = double.tryParse(priceController.text);
                if (nameController.text.isNotEmpty && price != null && price > 0 && selectedCategoryId != null) {
                  vm.addProduct(
                    name: nameController.text,
                    price: price,
                    categoryId: selectedCategoryId!,
                    emoji: emojiController.text.isEmpty ? '📦' : emojiController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('PŘIDAT', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesList(BuildContext context, POSNavigationViewModel navViewModel) {
    final tablesViewModel = context.watch<TablesViewModel>();

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Text(
            'VŠECHNY STOLY',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          ...tablesViewModel.allTables.map((table) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: TableCard(
                  table: table,
                  onTap: () {
                    if (table.status == TableStatus.free) {
                      _showPersonCountDialog(context, tablesViewModel, navViewModel, table.number);
                    } else {
                      navViewModel.selectTable(table.number);
                    }
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, POSNavigationViewModel navViewModel) {
    final productsViewModel = context.watch<ProductsViewModel>();
    final categories = productsViewModel.categories;

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Text(
            'KATEGORIE',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          ...categories.map((category) => _buildCategoryRow(
                context,
                navViewModel,
                category,
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    POSNavigationViewModel navViewModel,
    ProductCategory category,
  ) {
    return InkWell(
      onTap: () => navViewModel.selectCategory(category),
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(CornerRadius.md),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                category.title,
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, POSNavigationViewModel navViewModel) {
    final category = navViewModel.selectedCategory;
    if (category == null) return const SizedBox();

    final productsViewModel = context.watch<ProductsViewModel>();
    final products = productsViewModel.getProductsByCategory(category.id);

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Text(
            'PRODUKTY',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          ...products.map((product) => _buildProductRow(
                context,
                navViewModel,
                product,
              )),
        ],
      ),
    );
  }

  Widget _buildProductRow(
    BuildContext context,
    POSNavigationViewModel navViewModel,
    dynamic product,
  ) {
    return InkWell(
      onTap: () {
        final tablesViewModel = context.read<TablesViewModel>();
        final tableNumber = navViewModel.selectedTableNumber;

        if (tableNumber != null) {
          tablesViewModel.addProductToTable(tableNumber, product);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.backgroundSecondary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Vyberte stůl',
              style: AppTypography.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableDetail(BuildContext context, POSNavigationViewModel navViewModel) {
    final tablesViewModel = context.watch<TablesViewModel>();
    final tableNumber = navViewModel.selectedTableNumber;

    if (tableNumber == null) return _buildPlaceholder();

    final table = tablesViewModel.getTableByNumber(tableNumber);
    if (table == null) return _buildPlaceholder();

    final order = table.currentOrder;
    final currentTableNumber = tableNumber;

    return Container(
      color: AppColors.backgroundSecondary,
      child: Column(
        children: [
          // Table info header
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            color: AppColors.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (order != null && order.personCount > 0) ...[
                  Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${order.personCount}',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: Spacing.md),
                ],
                if (table.elapsedMinutes != null) ...[
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: Spacing.xxs),
                  Text('${table.elapsedMinutes} min',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: Spacing.lg),
                ],
                Text(
                  CurrencyFormatter.format(table.displayAmount),
                  style: AppTypography.displaySmall
                      .copyWith(color: AppColors.textPrimary),
                ),
                if (order != null && order.discountAmount > 0) ...[
                  const SizedBox(width: Spacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '- ${CurrencyFormatter.format(order.discountAmount)}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Order items or empty state
          if (order == null || order.items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: Spacing.md),
                    Text('Žádné položky',
                        style: AppTypography.h4.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: Spacing.xs),
                    Text('Vyberte kategorii a přidejte produkty',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  Row(
                    children: [
                      Text('OBJEDNÁVKA',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      // Discount button
                      TextButton.icon(
                        onPressed: () => _showDiscountDialog(context, tablesViewModel, currentTableNumber, order),
                        icon: const Icon(Icons.local_offer, size: 16),
                        label: const Text('Sleva'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm),
                        child: GestureDetector(
                          onLongPress: () => _showStornoDialog(
                              context, tablesViewModel, currentTableNumber, item),
                          child: Stack(
                            children: [
                              OrderItemRow(
                                item: item,
                                onQuantityChange: (newQty) {
                                  tablesViewModel.updateOrderItemQuantity(
                                      currentTableNumber, item.id, newQty);
                                },
                                onDelete: () {
                                  tablesViewModel.deleteOrderItem(
                                      currentTableNumber, item.id);
                                },
                              ),
                              if (item.isStorno)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('STORNO',
                                          style: AppTypography.labelSmall.copyWith(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: Spacing.lg),
                  _buildPriceBreakdown(order),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showStornoDialog(BuildContext context, TablesViewModel tablesVM,
      int tableNumber, dynamic item) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Storno položky',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.product.name} ×${item.quantity}  •  ${CurrencyFormatter.format(item.totalPrice)}',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  labelText: 'Důvod storna (volitelné)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              tablesVM.stornoItem(tableNumber, item.id,
                  reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Provést storno'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, TablesViewModel tablesVM,
      int tableNumber, dynamic order) {
    final amountCtrl = TextEditingController(
        text: order.discountAmount > 0
            ? order.discountAmount.toStringAsFixed(0)
            : '');
    final reasonCtrl = TextEditingController(text: order.discountReason ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sleva na účet',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Výše slevy', suffixText: 'Kč'),
              autofocus: true,
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: reasonCtrl,
              decoration:
                  const InputDecoration(labelText: 'Důvod (volitelné)'),
            ),
          ],
        ),
        actions: [
          if (order.discountAmount > 0)
            TextButton(
              onPressed: () {
                tablesVM.setDiscount(tableNumber, 0, null);
                Navigator.pop(ctx);
              },
              child: Text('Odebrat slevu',
                  style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(
                  amountCtrl.text.replaceAll(',', '.')) ?? 0;
              tablesVM.setDiscount(tableNumber, amount,
                  reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null);
              Navigator.pop(ctx);
            },
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(dynamic order) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(CornerRadius.md),
      ),
      child: Column(
        children: [
          _buildPriceRow('MEZISOUČET', order.subtotal, false),
          const SizedBox(height: Spacing.xs),
          _buildPriceRow('DPH (21%)', order.vat, false),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Divider(color: AppColors.divider),
          ),
          _buildPriceRow('CELKEM', order.total, true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? AppTypography.labelLarge : AppTypography.bodyMedium)
              .copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: (isBold ? AppTypography.h4 : AppTypography.monoMedium)
              .copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showPersonCountDialog(BuildContext context, TablesViewModel tablesVM,
      POSNavigationViewModel navVM, int tableNumber) {
    int count = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Stůl $tableNumber – počet hostů',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kolik hostů sedí u stolu?',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: Spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: count > 1 ? () => setS(() => count--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: Spacing.lg),
                  Text('$count',
                      style: AppTypography.displaySmall
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(width: Spacing.lg),
                  IconButton(
                    onPressed: () => setS(() => count++),
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: 8,
                children: [2, 3, 4, 5, 6, 8].map((n) => ActionChip(
                      label: Text('$n'),
                      onPressed: () => setS(() => count = n),
                      backgroundColor: count == n
                          ? AppColors.primary
                          : AppColors.backgroundTertiary,
                      labelStyle: TextStyle(
                          color: count == n ? Colors.white : AppColors.textPrimary),
                    )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                navVM.selectTable(tableNumber);
              },
              child: const Text('Přeskočit'),
            ),
            ElevatedButton(
              onPressed: () {
                tablesVM.setPersonCount(tableNumber, count);
                Navigator.pop(ctx);
                navVM.selectTable(tableNumber);
              },
              child: const Text('Otevřít stůl'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterSettingsDialog(BuildContext context) {
    final printer = context.read<PrinterService>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Row(
              children: [
                Icon(Icons.print, color: AppColors.textPrimary),
                const SizedBox(width: Spacing.sm),
                Text('Nastavení tiskárny', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Connection status
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(CornerRadius.md),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: printer.isConnected ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Text(
                            printer.isConnected
                                ? 'Připojeno: ${printer.connectedDevice?.name ?? printer.connectedDevice?.address ?? ''}'
                                : 'Nepřipojeno',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Action buttons
                  if (printer.isConnected) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          printer.printTestReceipt();
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Testovací účtenka odeslána na tiskárnu'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt, size: 20),
                        label: const Text('Testovací tisk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          printer.disconnect();
                          setDialogState(() {});
                        },
                        icon: const Icon(Icons.bluetooth_disabled, size: 20),
                        label: const Text('Odpojit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _searchAndConnectPrinter(context, printer);
                        },
                        icon: const Icon(Icons.bluetooth_searching, size: 20),
                        label: const Text('Vyhledat tiskárny'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('ZAVŘÍT', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _searchAndConnectPrinter(BuildContext context, PrinterService printer) async {
    // Show searching dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Hledám tiskárny...', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: const SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ),
    );

    final devices = await printer.getPairedDevices();

    if (!context.mounted) return;
    Navigator.pop(context);

    if (devices.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Žádné zařízení', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          content: Text(
            'Nejprve spárujte tiskárnu v nastavení Bluetooth vašeho tabletu.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }

    // Show devices list
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Spárovaná zařízení', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: devices.map((device) => InkWell(
              onTap: () async {
                Navigator.pop(dialogContext);

                // Show connecting dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.cardBackground,
                    title: Text('Připojuji...', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
                    content: SizedBox(
                      height: 60,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: Spacing.sm),
                            Text(device.name ?? device.address ?? '', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                final success = await printer.connect(device);

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Tiskárna připojena!'
                        : 'Připojení selhalo. Zkontrolujte, zda je tiskárna zapnutá.'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: Spacing.xs),
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(CornerRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth, color: AppColors.info, size: 24),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name ?? 'Neznámé zařízení',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                          ),
                          Text(
                            device.address ?? '',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
