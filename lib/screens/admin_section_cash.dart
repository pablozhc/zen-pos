import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/cash_movement_model.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';

class AdminSectionCash extends StatefulWidget {
  final List<Payment> payments;

  const AdminSectionCash({super.key, required this.payments});

  @override
  State<AdminSectionCash> createState() => _AdminSectionCashState();
}

class _AdminSectionCashState extends State<AdminSectionCash>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _fs = FirestoreService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalCashRevenue => widget.payments
      .where((p) => p.method == PaymentMethod.cash)
      .fold(0.0, (s, p) => s + p.amount);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(
              Spacing.lg, Spacing.lg, Spacing.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Pokladna',
                      style: AppTypography.h2
                          .copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showAddMovementDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Přidat pohyb'),
                  ),
                  const SizedBox(width: Spacing.sm),
                  OutlinedButton.icon(
                    onPressed: _showClosureDialog,
                    icon: const Icon(Icons.lock_clock, size: 18),
                    label: const Text('Uzávěrka'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Pohyb hotovosti'),
                  Tab(text: 'Uzávěrky'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMovementsTab(),
              _buildClosuresTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovementsTab() {
    return StreamBuilder<List<CashMovement>>(
      stream: _fs.cashMovementsStream(),
      builder: (context, snapshot) {
        final movements = snapshot.data ?? [];
        if (movements.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: Spacing.sm),
                Text('Žádné pohyby hotovosti',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: Spacing.sm),
                ElevatedButton(
                    onPressed: _showAddMovementDialog,
                    child: const Text('Přidat první pohyb')),
              ],
            ),
          );
        }

        double balance = 0;
        for (final m in movements.reversed) {
          balance += m.type.isPositive ? m.amount : -m.amount;
        }

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(Spacing.md),
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _balanceCard('Hotovost z tržeb',
                      CurrencyFormatter.format(_totalCashRevenue),
                      AppColors.success),
                  const SizedBox(width: Spacing.md),
                  _balanceCard('Pohyby', CurrencyFormatter.format(balance),
                      balance >= 0 ? AppColors.info : AppColors.error),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                itemCount: movements.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) => _movementRow(movements[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _balanceCard(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.h3.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _movementRow(CashMovement m) {
    final isPositive = m.type.isPositive;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: Spacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.type.title,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textPrimary)),
                if (m.note != null)
                  Text(m.note!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'} ${CurrencyFormatter.format(m.amount)}',
                style: AppTypography.labelMedium.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error),
              ),
              Text(_dateFormat.format(m.createdAt),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(width: Spacing.sm),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 18, color: AppColors.textTertiary),
            onPressed: () => _fs.deleteCashMovement(m.id),
          ),
        ],
      ),
    );
  }

  Widget _buildClosuresTab() {
    return StreamBuilder<List<DayClosure>>(
      stream: _fs.closuresStream(),
      builder: (context, snapshot) {
        final closures = snapshot.data ?? [];
        if (closures.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_clock_outlined,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: Spacing.sm),
                Text('Žádné uzávěrky',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: Spacing.sm),
                ElevatedButton(
                    onPressed: _showClosureDialog,
                    child: const Text('Provést první uzávěrku')),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: closures.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppColors.divider),
          itemBuilder: (_, i) => _closureRow(closures[i]),
        );
      },
    );
  }

  Widget _closureRow(DayClosure c) {
    final df = DateFormat('dd.MM.yyyy');
    final tf = DateFormat('HH:mm');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Uzávěrka ${df.format(c.closedAt)}',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textPrimary)),
                Text(
                    '${tf.format(c.openedAt)} – ${tf.format(c.closedAt)}  •  ${c.paymentCount} plateb',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyFormatter.format(c.totalRevenue),
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textPrimary)),
              Text(
                  'Hotovost: ${CurrencyFormatter.format(c.totalCash)} | Karta: ${CurrencyFormatter.format(c.totalCard)}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMovementDialog() {
    CashMovementType selectedType = CashMovementType.income;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Přidat pohyb hotovosti'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CashMovementType>(
                value: selectedType,
                items: [
                  CashMovementType.income,
                  CashMovementType.expense,
                ].map((t) => DropdownMenuItem(value: t, child: Text(t.title))).toList(),
                onChanged: (v) => setS(() => selectedType = v!),
                decoration: const InputDecoration(labelText: 'Typ pohybu'),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Částka (Kč)', suffixText: 'Kč'),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Poznámka'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(
                    amountCtrl.text.replaceAll(',', '.'));
                if (amount == null || amount <= 0) return;
                _fs.addCashMovement(CashMovement(
                  id: const Uuid().v4(),
                  type: selectedType,
                  amount: amount,
                  note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClosureDialog() {
    final openingCtrl = TextEditingController(text: '0');
    final closingCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final cashPayments =
        widget.payments.where((p) => p.method == PaymentMethod.cash);
    final cardPayments =
        widget.payments.where((p) => p.method == PaymentMethod.card);
    final totalCash =
        cashPayments.fold(0.0, (s, p) => s + p.amount);
    final totalCard =
        cardPayments.fold(0.0, (s, p) => s + p.amount);
    final totalTips =
        widget.payments.fold(0.0, (s, p) => s + p.tip);
    final totalRevenue =
        widget.payments.fold(0.0, (s, p) => s + p.totalWithTip);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provést uzávěrku'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Souhrn období:',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: Spacing.sm),
              _summaryRow('Celkové tržby',
                  CurrencyFormatter.format(totalRevenue)),
              _summaryRow(
                  'Hotovost', CurrencyFormatter.format(totalCash)),
              _summaryRow('Karta', CurrencyFormatter.format(totalCard)),
              _summaryRow(
                  'Spropitné', CurrencyFormatter.format(totalTips)),
              _summaryRow('Počet plateb', '${widget.payments.length}'),
              const Divider(height: Spacing.lg),
              TextField(
                controller: openingCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Počáteční stav pokladny (Kč)',
                    suffixText: 'Kč'),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: closingCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Skutečný stav pokladny (Kč)',
                    suffixText: 'Kč'),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Poznámka'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              final opening =
                  double.tryParse(openingCtrl.text.replaceAll(',', '.')) ??
                      0;
              final closing =
                  double.tryParse(closingCtrl.text.replaceAll(',', '.')) ??
                      0;
              final now = DateTime.now();
              _fs.addClosure(DayClosure(
                id: const Uuid().v4(),
                openedAt: now.subtract(const Duration(hours: 8)),
                closedAt: now,
                openingCash: opening,
                closingCash: closing,
                totalRevenue: totalRevenue,
                totalCash: totalCash,
                totalCard: totalCard,
                totalTips: totalTips,
                paymentCount: widget.payments.length,
                note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Uzávěrka provedena')),
              );
            },
            child: const Text('Provést uzávěrku'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary))),
          Text(value,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
