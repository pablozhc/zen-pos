import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'admin_widgets.dart';

class AdminSectionReceipts extends StatefulWidget {
  final List<Payment> payments;
  const AdminSectionReceipts({super.key, required this.payments});

  @override
  State<AdminSectionReceipts> createState() => _AdminSectionReceiptsState();
}

class _AdminSectionReceiptsState extends State<AdminSectionReceipts> {
  Payment? _selected;
  String _searchQuery = '';
  PaymentMethod? _filterMethod;
  final _df = DateFormat('dd.MM.yyyy HH:mm');

  List<Payment> get _filtered => widget.payments.where((p) {
    if (_filterMethod != null && p.method != _filterMethod) return false;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!(p.receiptNumber?.toLowerCase().contains(q) == true ||
          p.staffName?.toLowerCase().contains(q) == true ||
          'stůl ${p.tableNumber}'.contains(q))) return false;
    }
    return true;
  }).toList();

  Color _methodColor(PaymentMethod m) => switch (m) {
    PaymentMethod.card     => AppColors.info,
    PaymentMethod.cash     => AppColors.success,
    PaymentMethod.transfer => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildList()),
          if (_selected != null) ...[
            const VerticalDivider(width: 1, thickness: 0.5, color: AT.border),
            Expanded(flex: 2, child: _buildDetail(_selected!)),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;
    return Column(
      children: [
        Container(
          color: AT.bg,
          padding: const EdgeInsets.fromLTRB(AT.pagePad, AT.pagePad, AT.pagePad, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _filterPill('Vše', null),
                  const SizedBox(width: 6),
                  _filterPill('Karta', PaymentMethod.card),
                  const SizedBox(width: 6),
                  _filterPill('Hotovost', PaymentMethod.cash),
                  const Spacer(),
                  Text('${list.length} účtenek', style: AT.rowSub),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Hledat dle č. účtu, obsluhy, stolu…',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: AT.border),
        Expanded(
          child: list.isEmpty
              ? const AdminEmptyState(icon: Icons.receipt_long_rounded, title: 'Žádné účtenky', subtitle: 'Zatím nebyly přijaty žádné platby')
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: AT.border),
                  itemBuilder: (_, i) => _receiptRow(list[i]),
                ),
        ),
      ],
    );
  }

  Widget _filterPill(String label, PaymentMethod? method) {
    final isActive = _filterMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _filterMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AT.indigo : AT.bgWarm,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: AT.badge.copyWith(color: isActive ? Colors.white : AT.ink3)),
      ),
    );
  }

  Widget _receiptRow(Payment p) {
    final isSelected = _selected?.id == p.id;
    return InkWell(
      onTap: () => setState(() => _selected = p),
      child: Container(
        color: isSelected ? AT.indigo.withValues(alpha: 0.06) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: AT.rowPadV),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.receiptNumber ?? p.id.substring(0, 8).toUpperCase(), style: AT.rowTitle),
                  Text(_df.format(p.timestamp), style: AT.rowSub),
                ],
              ),
            ),
            Expanded(child: Text('Stůl ${p.tableNumber}', style: AT.rowSub)),
            Expanded(child: Text(p.staffName ?? '—', style: AT.rowSub)),
            AdminBadge(label: p.method.title, color: _methodColor(p.method)),
            const SizedBox(width: 16),
            Text(CurrencyFormatter.format(p.totalWithTip), style: AT.mono.copyWith(fontSize: 14)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18, color: AT.ink3),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(Payment p) {
    return Container(
      color: AT.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AT.pagePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Detail účtenky', style: AT.cardTitle.copyWith(fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => setState(() => _selected = null),
                  color: AT.ink3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _detailRow('Číslo účtu', p.receiptNumber ?? p.id.substring(0, 8).toUpperCase()),
                  _detailRow('Datum', _df.format(p.timestamp)),
                  _detailRow('Stůl', 'Stůl ${p.tableNumber}'),
                  _detailRow('Obsluha', p.staffName ?? '—'),
                  _detailRow('Platba', p.method.title),
                  _detailRow('Počet osob', '${p.personCount}', last: p.discount == 0),
                  if (p.discount > 0)
                    _detailRow('Sleva', '− ${CurrencyFormatter.format(p.discount)}', color: AppColors.warning, last: true),
                ],
              ),
            ),
            const SizedBox(height: AT.cardGap),
            AdminCardSection(
              title: 'Položky',
              children: p.items.isEmpty
                  ? [Padding(
                      padding: const EdgeInsets.all(AT.rowPadH),
                      child: Text('(historická platba bez detailu položek)', style: AT.rowSub),
                    )]
                  : p.items.asMap().entries.map((e) {
                      final item = e.value;
                      return AdminListRow(
                        title: item.productName,
                        subtitle: item.addons.isNotEmpty ? item.addons.map((a) => a.optionName).join(', ') : null,
                        value: CurrencyFormatter.format(item.totalPrice),
                        trailing: Text('${item.quantity}×', style: AT.rowSub),
                        showDivider: e.key < p.items.length - 1,
                      );
                    }).toList(),
            ),
            const SizedBox(height: AT.cardGap),
            AdminCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (p.tip > 0) _detailRow('Spropitné', CurrencyFormatter.format(p.tip), color: AppColors.success),
                  _detailRow('Celkem', CurrencyFormatter.format(p.totalWithTip), color: AT.indigo, bold: true, last: true),
                ],
              ),
            ),
            if (p.stornos.isNotEmpty) ...[
              const SizedBox(height: AT.cardGap),
              AdminCardSection(
                title: 'Storna',
                children: p.stornos.asMap().entries.map((e) {
                  final s = e.value;
                  return AdminListRow(
                    title: '${s.productName} ×${s.quantity}',
                    value: '− ${CurrencyFormatter.format(s.amount)}',
                    showDivider: e.key < p.stornos.length - 1,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool bold = false, bool last = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: AT.rowPadV),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text(label, style: AT.rowSub)),
              Expanded(child: Text(value, style: AT.rowTitle.copyWith(
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ))),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, thickness: 0.5, color: AT.border),
      ],
    );
  }
}
