import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../utils/currency_formatter.dart';

class OrderItemRow extends StatelessWidget {
  final OrderItem item;
  final ValueChanged<int> onQuantityChange;
  final VoidCallback onDelete;

  const OrderItemRow({
    super.key,
    required this.item,
    required this.onQuantityChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(CornerRadius.md),
        boxShadow: const [AppShadows.level1],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name with emoji
                Text(
                  '${item.product.emoji} ${item.product.name}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                // Note if exists
                if (item.note != null) ...[
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    item.note!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: Spacing.xxs),

                // Timestamp
                Text(
                  TimeOfDay.fromDateTime(item.timestamp).format(context),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: Spacing.sm),

          // Quantity controls
          Row(
            children: [
              IconButton(
                onPressed: () => onQuantityChange(item.quantity - 1),
                icon: const Icon(Icons.remove_circle),
                color: item.quantity == 1 ? AppColors.error : AppColors.textSecondary,
                iconSize: 24,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
              SizedBox(
                width: 24,
                child: Text(
                  '${item.quantity}',
                  style: AppTypography.monoMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => onQuantityChange(item.quantity + 1),
                icon: const Icon(Icons.add_circle),
                color: AppColors.primary,
                iconSize: 24,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ],
          ),

          const SizedBox(width: Spacing.sm),

          // Price
          SizedBox(
            width: 80,
            child: Text(
              CurrencyFormatter.format(item.product.price * item.quantity),
              style: AppTypography.monoMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
