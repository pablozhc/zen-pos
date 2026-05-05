import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../utils/currency_formatter.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;

  const ProductTile({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(Spacing.xs),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(CornerRadius.md),
          boxShadow: const [AppShadows.level1],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product icon/emoji background
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(CornerRadius.md),
              ),
              child: Center(
                child: Text(
                  product.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),

            // Name
            Text(
              product.name,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacing.xxs),

            // Price
            Text(
              CurrencyFormatter.format(product.price),
              style: AppTypography.monoMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: Spacing.xs),

            // Quantity badge or add indicator
            if (quantity > 0)
              Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(CornerRadius.full),
                ),
                child: Center(
                  child: Text(
                    '$quantity',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
