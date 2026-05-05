import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'admin_widgets.dart';

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

  double get _totalRevenue   => payments.fold(0.0, (s, p) => s + p.totalWithTip);
  double get _totalDiscount  => payments.fold(0.0, (s, p) => s + p.discount);
  double get _totalTips      => payments.fold(0.0, (s, p) => s + p.tip);
  double get _estimatedCost  => _totalRevenue * 0.15;
  double get _grossProfit    => _totalRevenue - _estimatedCost;
  double get _margin         => _totalRevenue > 0 ? (_grossProfit / _totalRevenue) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AdminContent(
        children: [
          AdminKpiGrid(cards: [
            AdminKpiCard(value: CurrencyFormatter.format(_grossProfit),  label: 'Zisk s DPH',    icon: Icons.trending_up_rounded,    accentColor: AppColors.success),
            AdminKpiCard(value: '${_margin.toStringAsFixed(1)}%',        label: 'Marže',          icon: Icons.percent_rounded,         accentColor: AppColors.info),
            AdminKpiCard(value: CurrencyFormatter.format(_totalRevenue), label: 'Tržby s DPH',   icon: Icons.receipt_long_rounded,    accentColor: AppColors.primary),
            AdminKpiCard(value: CurrencyFormatter.format(_estimatedCost),label: 'Náklady s DPH', icon: Icons.shopping_cart_rounded,   accentColor: AppColors.error),
          ]),
          const SizedBox(height: AT.cardGap),
          AdminCardSection(
            title: 'Detailní rozpis',
            children: [
              _breakdownRow('Celkové tržby',     CurrencyFormatter.format(_totalRevenue)),
              _breakdownRow('Spropitné',          CurrencyFormatter.format(_totalTips),         color: AppColors.success),
              _breakdownRow('Poskytnuté slevy',   '− ${CurrencyFormatter.format(_totalDiscount)}', color: AppColors.warning),
              _breakdownRow('Odhadované náklady', '− ${CurrencyFormatter.format(_estimatedCost)}', color: AppColors.error),
              const Divider(height: 1, thickness: 0.5, color: AT.border),
              _breakdownRow('Hrubý zisk',         CurrencyFormatter.format(_grossProfit),       color: AppColors.success, bold: true),
            ],
          ),
          const SizedBox(height: AT.cardGap),
          if (payments.isNotEmpty) _buildPaymentBreakdown(),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: AT.rowPadV),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? AT.rowTitle.copyWith(fontWeight: FontWeight.w700) : AT.rowTitle.copyWith(color: AT.ink2))),
          Text(value, style: AT.rowValue.copyWith(color: color ?? AT.ink1, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown() {
    final byMethod = <PaymentMethod, double>{};
    for (final p in payments) {
      byMethod[p.method] = (byMethod[p.method] ?? 0) + p.totalWithTip;
    }

    final rows = PaymentMethod.values.where((m) => (byMethod[m] ?? 0) > 0).toList();

    return AdminCardSection(
      title: 'Tržby dle způsobu platby',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: 8),
          child: Row(children: [
            Expanded(child: Text('Způsob platby', style: AT.sectionLabel)),
            Text('Příjmy',  style: AT.sectionLabel),
            const SizedBox(width: 48),
            Text('Počet', style: AT.sectionLabel),
          ]),
        ),
        const Divider(height: 1, thickness: 0.5, color: AT.border),
        ...rows.map((method) {
          final amt   = byMethod[method] ?? 0;
          final count = payments.where((p) => p.method == method).length;
          return AdminListRow(
            title: method.title,
            value: CurrencyFormatter.format(amt),
            trailing: SizedBox(width: 48, child: Text('$count', style: AT.rowSub, textAlign: TextAlign.right)),
            showDivider: method != rows.last,
          );
        }),
        const Divider(height: 1, thickness: 0.5, color: AT.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: AT.rowPadV),
          child: Row(children: [
            Expanded(child: Text('Celkem', style: AT.rowTitle.copyWith(fontWeight: FontWeight.w700))),
            Text(CurrencyFormatter.format(_totalRevenue), style: AT.rowValue.copyWith(color: AT.indigo)),
            const SizedBox(width: 48),
          ]),
        ),
      ],
    );
  }
}
