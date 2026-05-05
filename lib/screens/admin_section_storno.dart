import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';

class AdminSectionStorno extends StatelessWidget {
  final List<Payment> payments;
  final String periodLabel;

  const AdminSectionStorno({
    super.key,
    required this.payments,
    required this.periodLabel,
  });

  List<StornoRecord> get _allStornos =>
      payments.expand((p) => p.stornos).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  double get _totalStornoAmount =>
      _allStornos.fold(0.0, (s, r) => s + r.amount);

  double get _totalRevenue =>
      payments.fold(0.0, (s, p) => s + p.totalWithTip);

  double get _totalDiscount =>
      payments.fold(0.0, (s, p) => s + p.discount);

  @override
  Widget build(BuildContext context) {
    final stornos = _allStornos;
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Přehled storen a slev',
                  style:
                      AppTypography.h2.copyWith(color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(periodLabel,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.trending_down,
                  'Možná ztráta (storna)',
                  CurrencyFormatter.format(_totalStornoAmount),
                  AppColors.error,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _statCard(
                  Icons.receipt_long,
                  'Suma tržeb s DPH',
                  CurrencyFormatter.format(_totalRevenue),
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _statCard(
                  Icons.local_offer,
                  'Celkové slevy',
                  CurrencyFormatter.format(_totalDiscount),
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _statCard(
                  Icons.format_list_numbered,
                  'Počet záznamů',
                  '${stornos.length}',
                  AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          if (stornos.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(Spacing.xl),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: AppColors.success),
                    const SizedBox(height: Spacing.sm),
                    Text('Žádná storna v tomto období',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('Produkt',
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            child: Text('Množství',
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            child: Text('Částka',
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            child: Text('Obsluha',
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            flex: 2,
                            child: Text('Datum',
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            flex: 2,
                            child: Text('Důvod',
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  ...stornos.map((s) => Column(
                        children: [
                          Divider(height: 1, color: AppColors.divider),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.md, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: Text(s.productName,
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textPrimary))),
                                Expanded(
                                    child: Text('${s.quantity}×',
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary))),
                                Expanded(
                                    child: Text(
                                        '- ${CurrencyFormatter.format(s.amount)}',
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.error))),
                                Expanded(
                                    child: Text(s.authorName ?? '—',
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary))),
                                Expanded(
                                    flex: 2,
                                    child: Text(df.format(s.timestamp),
                                        style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary))),
                                Expanded(
                                    flex: 2,
                                    child: Text(s.reason ?? '—',
                                        style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary))),
                              ],
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ],

          // Discounts section
          const SizedBox(height: Spacing.xl),
          Text('Přehled slev',
              style:
                  AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: Spacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ...payments
                    .where((p) => p.discount > 0)
                    .map((p) => Column(
                          children: [
                            if (p != payments.firstWhere((x) => x.discount > 0))
                              Divider(height: 1, color: AppColors.divider),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.md, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          p.receiptNumber ??
                                              p.id.substring(0, 8),
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color:
                                                      AppColors.textPrimary))),
                                  Expanded(
                                      child: Text(
                                          df.format(p.timestamp),
                                          style: AppTypography.caption.copyWith(
                                              color:
                                                  AppColors.textSecondary))),
                                  Expanded(
                                      child: Text(p.staffName ?? '—',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color: AppColors
                                                      .textSecondary))),
                                  Expanded(
                                      child: Text(
                                          '- ${CurrencyFormatter.format(p.discount)}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color: AppColors.warning))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          p.discountReason ?? '—',
                                          style: AppTypography.caption.copyWith(
                                              color:
                                                  AppColors.textSecondary))),
                                ],
                              ),
                            ),
                          ],
                        ))
                    .toList()
                    .let((list) => list.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(Spacing.lg),
                              child: Center(
                                child: Text('Žádné slevy v tomto období',
                                    style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textSecondary)),
                              ),
                            )
                          ]
                        : list),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _ListExt<T> on List<T> {
  R let<R>(R Function(List<T>) fn) => fn(this);
}
