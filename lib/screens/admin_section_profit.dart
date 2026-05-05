import 'package:flutter/material.dart';

import '../models/payment_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';

class AdminSectionProfit extends StatelessWidget {
  final List<Payment> payments;
  final String periodLabel;
  final String dateRangeLabel;

  const AdminSectionProfit({
    super.key,
    required this.payments,
    required this.periodLabel,
    required this.dateRangeLabel,
  });

  double get _totalRevenue =>
      payments.fold(0.0, (s, p) => s + p.totalWithTip);

  double get _totalDiscount =>
      payments.fold(0.0, (s, p) => s + p.discount);

  double get _totalTips =>
      payments.fold(0.0, (s, p) => s + p.tip);

  // Hrubý zisk = tržby (náklady nejsou v demo datech, takže použijeme 85% marži jako příklad)
  double get _estimatedCost => _totalRevenue * 0.15;
  double get _grossProfit => _totalRevenue - _estimatedCost;
  double get _margin =>
      _totalRevenue > 0 ? (_grossProfit / _totalRevenue) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Zisk', style: AppTypography.h2.copyWith(color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const SizedBox(height: 4),
          Text(dateRangeLabel,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                  child: _statCard(Icons.trending_up, 'Zisk s DPH',
                      CurrencyFormatter.format(_grossProfit), AppColors.success)),
              const SizedBox(width: Spacing.md),
              Expanded(
                  child: _statCard(Icons.percent, 'Marže',
                      '${_margin.toStringAsFixed(1)}%', AppColors.info)),
              const SizedBox(width: Spacing.md),
              Expanded(
                  child: _statCard(Icons.receipt_long, 'Tržby s DPH',
                      CurrencyFormatter.format(_totalRevenue), AppColors.primary)),
              const SizedBox(width: Spacing.md),
              Expanded(
                  child: _statCard(Icons.shopping_cart, 'Náklady s DPH',
                      CurrencyFormatter.format(_estimatedCost), AppColors.error)),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          _buildBreakdownCard(),
          const SizedBox(height: Spacing.lg),
          _buildPaymentMethodBreakdown(),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value,
                    style:
                        AppTypography.h3.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detailní rozpis',
              style:
                  AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: Spacing.md),
          _breakdownRow('Celkové tržby', CurrencyFormatter.format(_totalRevenue)),
          _breakdownRow('Spropitné', CurrencyFormatter.format(_totalTips),
              color: AppColors.success),
          _breakdownRow('Poskytnuté slevy',
              '- ${CurrencyFormatter.format(_totalDiscount)}',
              color: AppColors.warning),
          _breakdownRow('Odhadované náklady',
              '- ${CurrencyFormatter.format(_estimatedCost)}',
              color: AppColors.error),
          const Divider(height: Spacing.lg),
          _breakdownRow('Hrubý zisk', CurrencyFormatter.format(_grossProfit),
              bold: true, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBreakdown() {
    final byMethod = <PaymentMethod, double>{};
    for (final p in payments) {
      byMethod[p.method] = (byMethod[p.method] ?? 0) + p.totalWithTip;
    }
    if (byMethod.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tržby dle způsobu platby',
              style:
                  AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: Spacing.md),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppColors.backgroundTertiary),
                children: [
                  _tableHeader('Způsob platby'),
                  _tableHeader('Příjmy s DPH'),
                  _tableHeader('Počet'),
                ],
              ),
              ...PaymentMethod.values.map((method) {
                final amount = byMethod[method] ?? 0;
                final count =
                    payments.where((p) => p.method == method).length;
                if (amount == 0) return null;
                return TableRow(children: [
                  _tableCell(method.title),
                  _tableCell(CurrencyFormatter.format(amount)),
                  _tableCell('$count'),
                ]);
              }).whereType<TableRow>(),
              TableRow(children: [
                _tableCell('Celkem', bold: true),
                _tableCell(CurrencyFormatter.format(_totalRevenue), bold: true),
                _tableCell('${payments.length}', bold: true),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: bold ? FontWeight.w600 : null)),
          ),
          Text(value,
              style: AppTypography.bodyMedium.copyWith(
                  color: color ?? AppColors.textPrimary,
                  fontWeight: bold ? FontWeight.w700 : null)),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(text,
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      );

  Widget _tableCell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(text,
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: bold ? FontWeight.w600 : null)),
      );
}
