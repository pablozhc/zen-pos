import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/tables_viewmodel.dart';
import '../models/table_model.dart';
import '../widgets/order_item_row.dart';
import '../widgets/primary_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';
import 'payment_screen.dart';
import 'new_order_screen.dart';

class TableDetailScreen extends StatelessWidget {
  final int tableNumber;

  const TableDetailScreen({
    super.key,
    required this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    return _TableDetailView(tableNumber: tableNumber);
  }
}

class _TableDetailView extends StatelessWidget {
  final int tableNumber;

  const _TableDetailView({required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TablesViewModel>();
    final table = viewModel.getTableByNumber(tableNumber);

    if (table == null || table.currentOrder == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Stůl $tableNumber'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Žádná aktivní objednávka',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
                child: PrimaryButton(
                  title: 'Nová objednávka',
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewOrderScreen(
                          preselectedTableNumber: tableNumber,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final order = table.currentOrder!;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, table),

            // Order items list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order items
                    Text(
                      'OBJEDNÁVKA',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: OrderItemRow(
                            item: item,
                            onQuantityChange: (newQty) =>
                                _updateItemQuantity(context, item, newQty),
                            onDelete: () => _deleteItem(context, item),
                          ),
                        )),

                    const SizedBox(height: Spacing.md),

                    // Add more items button
                    InkWell(
                      onTap: () => _addMoreItems(context),
                      child: Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(CornerRadius.md),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: Spacing.xs),
                            Text(
                              'PŘIDAT POLOŽKY',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: Spacing.xl),

                    // Price breakdown
                    _buildPriceBreakdown(order),
                  ],
                ),
              ),
            ),

            // Action buttons
            _buildActionButtons(context, table),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TableModel table) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      color: AppColors.background,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'STŮL ${table.number}',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // TODO: Edit/settings
                },
                icon: const Icon(Icons.more_vert),
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (table.elapsedMinutes != null) ...[
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: Spacing.xxs),
                Text(
                  '${table.elapsedMinutes} min',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: Spacing.lg),
              ],
              Text(
                CurrencyFormatter.format(table.displayAmount),
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(order) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(CornerRadius.md),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            'MEZISOUČET',
            order.subtotal,
            false,
          ),
          const SizedBox(height: Spacing.xs),
          _buildPriceRow(
            'DPH (21%)',
            order.vat,
            false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Divider(color: AppColors.divider),
          ),
          _buildPriceRow(
            'CELKEM',
            order.total,
            true,
          ),
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

  Widget _buildActionButtons(BuildContext context, TableModel table) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            title: 'ZAPLATIT',
            icon: Icons.payment,
            onPressed: () => _navigateToPayment(context, table),
            height: 60,
          ),
        ],
      ),
    );
  }

  void _updateItemQuantity(context, item, int newQty) {
    // TODO: Update item quantity in order
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Množství upraveno na $newQty'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _deleteItem(context, item) {
    // TODO: Delete item from order
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.product.name} odstraněno'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'ZPĚT',
          onPressed: () {
            // TODO: Undo delete
          },
        ),
      ),
    );
  }

  void _addMoreItems(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewOrderScreen(
          preselectedTableNumber: tableNumber,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToPayment(BuildContext context, TableModel table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(table: table),
      ),
    );
  }
}
