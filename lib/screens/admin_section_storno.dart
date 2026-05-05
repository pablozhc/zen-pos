import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'admin_widgets.dart';

class AdminSectionStorno extends StatelessWidget {
  final List<Payment> payments;
  final String periodLabel;

  const AdminSectionStorno({super.key, required this.payments, required this.periodLabel});

  List<StornoRecord> get _allStornos =>
      payments.expand((p) => p.stornos).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  double get _totalStornoAmount => _allStornos.fold(0.0, (s, r) => s + r.amount);
  double get _totalRevenue      => payments.fold(0.0, (s, p) => s + p.totalWithTip);
  double get _totalDiscount     => payments.fold(0.0, (s, p) => s + p.discount);

  @override
  Widget build(BuildContext context) {
    final stornos = _allStornos;
    final discounts = payments.where((p) => p.discount > 0).toList();
    final df = DateFormat('dd.MM. HH:mm');

    return Expanded(
      child: AdminContent(
        children: [
          AdminKpiGrid(cards: [
            AdminKpiCard(value: CurrencyFormatter.format(_totalStornoAmount), label: 'Možná ztráta (storna)', icon: Icons.trending_down_rounded, accentColor: AppColors.error),
            AdminKpiCard(value: CurrencyFormatter.format(_totalRevenue),      label: 'Suma tržeb s DPH',      icon: Icons.receipt_long_rounded,    accentColor: AppColors.primary),
            AdminKpiCard(value: CurrencyFormatter.format(_totalDiscount),     label: 'Celkové slevy',         icon: Icons.local_offer_rounded,      accentColor: AppColors.warning),
            AdminKpiCard(value: '${stornos.length}',                          label: 'Počet záznamů',         icon: Icons.format_list_numbered_rounded, accentColor: AppColors.info),
          ]),
          const SizedBox(height: AT.cardGap),
          AdminCardSection(
            title: 'Storna',
            children: stornos.isEmpty
                ? [const AdminEmptyState(icon: Icons.check_circle_outline_rounded, title: 'Žádná storna v tomto období')]
                : [
                    _tableHeader(['Produkt', 'Mn.', 'Částka', 'Obsluha', 'Datum', 'Důvod']),
                    ...stornos.asMap().entries.map((e) {
                      final s = e.value;
                      return _tableRow([
                        s.productName,
                        '${s.quantity}×',
                        '− ${CurrencyFormatter.format(s.amount)}',
                        s.authorName ?? '—',
                        df.format(s.timestamp),
                        s.reason ?? '—',
                      ], valueColor: AppColors.error, valueIndex: 2, showDivider: e.key < stornos.length - 1);
                    }),
                  ],
          ),
          const SizedBox(height: AT.cardGap),
          AdminCardSection(
            title: 'Slevy',
            children: discounts.isEmpty
                ? [const AdminEmptyState(icon: Icons.local_offer_rounded, title: 'Žádné slevy v tomto období')]
                : discounts.asMap().entries.map((e) {
                    final p = e.value;
                    return AdminListRow(
                      title: p.receiptNumber ?? p.id.substring(0, 8),
                      subtitle: df.format(p.timestamp),
                      value: '− ${CurrencyFormatter.format(p.discount)}',
                      trailing: p.discountReason != null
                          ? AdminBadge(label: p.discountReason!, color: AppColors.warning)
                          : null,
                      showDivider: e.key < discounts.length - 1,
                    );
                  }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> labels) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: 8),
      color: const Color(0xFFF3F0EB),
      child: Row(
        children: labels.map((l) => Expanded(child: Text(l, style: AT.sectionLabel))).toList(),
      ),
    );
  }

  Widget _tableRow(List<String> cells, {Color? valueColor, int? valueIndex, bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: AT.rowPadV - 2),
          child: Row(
            children: cells.asMap().entries.map((e) {
              final isValue = e.key == valueIndex;
              return Expanded(
                child: Text(
                  e.value,
                  style: isValue
                      ? AT.rowSub.copyWith(color: valueColor, fontWeight: FontWeight.w600)
                      : AT.rowSub,
                ),
              );
            }).toList(),
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 0.5, color: AT.border),
      ],
    );
  }
}
