import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500 && onSwipeLeft != null) {
            // Swipe left - quick payment
            onSwipeLeft!();
          } else if (details.primaryVelocity! > 500 && onSwipeRight != null) {
            // Swipe right - detail/edit
            onSwipeRight!();
          }
        }
      },
      child: Container(
        height: 60, // Fixed height for all tables
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
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
            // Status indicator dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: table.status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Table number
            Expanded(
              child: Text(
                'STŮL ${table.number}',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Amount (only for occupied tables)
            if (table.status == TableStatus.occupied)
              Text(
                CurrencyFormatter.format(table.displayAmount),
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

            const SizedBox(width: Spacing.xs),

            // Chevron
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
