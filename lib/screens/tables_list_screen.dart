import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/tables_viewmodel.dart';
import '../widgets/table_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';
import 'new_order_screen.dart';
import 'table_detail_screen.dart';

class TablesListScreen extends StatelessWidget {
  const TablesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TablesListView();
  }
}

class _TablesListView extends StatelessWidget {
  const _TablesListView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TablesViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                _buildHeader(context, viewModel),

                // Search bar
                _buildSearchBar(context),

                // Tables list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: viewModel.refresh,
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(Spacing.md),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // Active tables section
                              if (viewModel.activeTables.isNotEmpty) ...[
                                _buildSectionHeader('AKTIVNÍ STOLY'),
                                const SizedBox(height: Spacing.md),
                                ...viewModel.activeTables.map(
                                  (table) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: Spacing.md,
                                    ),
                                    child: TableCard(
                                      table: table,
                                      onTap: () => _navigateToTableDetail(
                                        context,
                                        table.number,
                                      ),
                                      onSwipeLeft: () =>
                                          viewModel.quickPayment(table),
                                      onSwipeRight: () => _navigateToTableDetail(
                                        context,
                                        table.number,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Spacing.lg),
                              ],

                              // Free tables section
                              if (viewModel.freeTables.isNotEmpty)
                                _buildFreeTablesSection(context, viewModel),
                            ]),
                          ),
                        ),
                        // Bottom padding for floating button
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 100),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating action button
            Positioned(
              bottom: Spacing.xl,
              left: 0,
              right: 0,
              child: Center(
                child: _buildFloatingButton(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TablesViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      color: AppColors.background,
      child: Row(
        children: [
          Text(
            'STOLY',
            style: AppTypography.h1.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(viewModel.todayRevenue),
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${viewModel.todayOrders} objednávek',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Najít stůl nebo položku...',
                  hintStyle: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildFreeTablesSection(
    BuildContext context,
    TablesViewModel viewModel,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: viewModel.toggleShowFreeTables,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(
              children: [
                Text(
                  'VOLNÉ STOLY',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '(${viewModel.freeTables.length})',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Icon(
                  viewModel.showFreeTables
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (viewModel.showFreeTables) ...[
          const SizedBox(height: Spacing.md),
          ...viewModel.freeTables.map(
            (table) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: TableCard(
                table: table,
                onTap: () {
                  viewModel.preselectedTable = table.number;
                  _navigateToNewOrder(context);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(CornerRadius.full),
      child: InkWell(
        onTap: () => _navigateToNewOrder(context),
        borderRadius: BorderRadius.circular(CornerRadius.full),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(CornerRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                'NOVÁ OBJEDNÁVKA',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNewOrder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NewOrderScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToTableDetail(BuildContext context, int tableNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TableDetailScreen(tableNumber: tableNumber),
      ),
    );
  }
}
