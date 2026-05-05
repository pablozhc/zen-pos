import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isLoading;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
    this.isDestructive = false,
    this.isLoading = false,
    this.height = 70.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textTertiary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: Spacing.xs),
                  ],
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
