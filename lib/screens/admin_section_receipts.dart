import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';

class AdminSectionReceipts extends StatefulWidget {
  final List<Payment> payments;

  const AdminSectionReceipts({super.key, required this.payments});

  @override
  State<AdminSectionReceipts> createState() => _AdminSectionReceiptsState();
}

class _AdminSectionReceiptsState extends State<AdminSectionReceipts> {
  Payment? _selectedPayment;
  String _searchQuery = '';
  PaymentMethod? _filterMethod;
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  List<Payment> get _filtered {
    return widget.payments.where((p) {
      if (_filterMethod != null && p.method != _filterMethod) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!(p.receiptNumber?.toLowerCase().contains(q) == true ||
            p.staffName?.toLowerCase().contains(q) == true ||
            'stůl ${p.tableNumber}'.contains(q))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildList()),
        if (_selectedPayment != null) ...[
          VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(flex: 2, child: _buildDetail(_selectedPayment!)),
        ],
      ],
    );
  }

  Widget _buildList() {
    final list = _filtered;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          color: AppColors.background,
          child: Column(
            children: [
              Row(
                children: [
                  Text('Účtenky',
                      style: AppTypography.h2
                          .copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  _filterChip('Vše', null),
                  const SizedBox(width: 6),
                  _filterChip('Karta', PaymentMethod.card),
                  const SizedBox(width: 6),
                  _filterChip('Hotovost', PaymentMethod.cash),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Hledat dle č. účtu, obsluhy, stolu...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text('Žádné účtenky',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textTertiary)))
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, i) => _receiptRow(list[i]),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, PaymentMethod? method) {
    final isActive = _filterMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _filterMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: AppTypography.labelSmall.copyWith(
                color: isActive ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _receiptRow(Payment p) {
    final isSelected = _selectedPayment?.id == p.id;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 12),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.receiptNumber ?? p.id.substring(0, 8).toUpperCase(),
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(_dateFormat.format(p.timestamp),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: Text('Stůl ${p.tableNumber}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(p.staffName ?? '—',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _methodColor(p.method).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(p.method.title,
                    style: AppTypography.caption
                        .copyWith(color: _methodColor(p.method)),
                    textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(CurrencyFormatter.format(p.totalWithTip),
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(Payment p) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Detail účtenky',
                    style: AppTypography.h3
                        .copyWith(color: AppColors.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      setState(() => _selectedPayment = null),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            _detailRow('Číslo účtu',
                p.receiptNumber ?? p.id.substring(0, 8).toUpperCase()),
            _detailRow('Datum', _dateFormat.format(p.timestamp)),
            _detailRow('Stůl', 'Stůl ${p.tableNumber}'),
            _detailRow('Obsluha', p.staffName ?? '—'),
            _detailRow('Platba', p.method.title),
            _detailRow('Počet osob', '${p.personCount}'),
            if (p.discount > 0)
              _detailRow('Sleva',
                  '- ${CurrencyFormatter.format(p.discount)}',
                  color: AppColors.warning),
            const Divider(height: Spacing.xl),
            Text('Položky',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: Spacing.sm),
            if (p.items.isEmpty)
              Text('(historická platba bez detailu položek)',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiary))
            else
              ...p.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary)),
                              if (item.addons.isNotEmpty)
                                Text(
                                    item.addons
                                        .map((a) => a.optionName)
                                        .join(', '),
                                    style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text('${item.quantity}×',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(width: Spacing.md),
                        Text(CurrencyFormatter.format(item.totalPrice),
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                  )),
            const Divider(height: Spacing.xl),
            if (p.tip > 0)
              _detailRow('Spropitné', CurrencyFormatter.format(p.tip),
                  color: AppColors.success),
            _detailRow('Celkem',
                CurrencyFormatter.format(p.totalWithTip),
                bold: true, color: AppColors.primary),
            if (p.stornos.isNotEmpty) ...[
              const Divider(height: Spacing.xl),
              Text('Storna',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.error)),
              const SizedBox(height: Spacing.sm),
              ...p.stornos.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                                '${s.productName} ×${s.quantity}',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary))),
                        Text('- ${CurrencyFormatter.format(s.amount)}',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.error)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodyMedium.copyWith(
                    color: color ?? AppColors.textPrimary,
                    fontWeight: bold ? FontWeight.w700 : null)),
          ),
        ],
      ),
    );
  }

  Color _methodColor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return AppColors.info;
      case PaymentMethod.cash:
        return AppColors.success;
      case PaymentMethod.transfer:
        return AppColors.warning;
    }
  }
}

