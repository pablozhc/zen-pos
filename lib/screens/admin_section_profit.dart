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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 20, 0),
          height: 56,
          color: const Color(0xFFFAF8F5),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Zisk',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E), letterSpacing: -0.3)),
                  Text(dateRangeLabel,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(periodLabel,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _statCard(Icons.trending_up_rounded, 'Zisk s DPH', CurrencyFormatter.format(_grossProfit), AppColors.success),
                    _statCard(Icons.percent_rounded, 'Marže', '${_margin.toStringAsFixed(1)}%', AppColors.info),
                    _statCard(Icons.receipt_long_rounded, 'Tržby s DPH', CurrencyFormatter.format(_totalRevenue), AppColors.primary),
                    _statCard(Icons.shopping_cart_rounded, 'Náklady s DPH', CurrencyFormatter.format(_estimatedCost), AppColors.error),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBreakdownCard(),
                const SizedBox(height: 16),
                _buildPaymentMethodBreakdown(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color accentColor) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 1),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1, color: Color(0xFF1A0F0A))),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(icon, color: accentColor, size: 12),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9A8F85), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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

