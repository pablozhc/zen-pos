import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/cash_movement_model.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'admin_widgets.dart';

class AdminSectionCash extends StatefulWidget {
  final List<Payment> payments;
  const AdminSectionCash({super.key, required this.payments});

  @override
  State<AdminSectionCash> createState() => _AdminSectionCashState();
}

class _AdminSectionCashState extends State<AdminSectionCash> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _fs = FirestoreService();
  final _df = DateFormat('dd.MM.yyyy HH:mm');

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
    return Expanded(
      child: Column(
        children: [
          Container(
            color: AT.bg,
            padding: const EdgeInsets.fromLTRB(AT.pagePad, AT.pagePad, AT.pagePad, 0),
            child: Row(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [Tab(text: 'Pohyb hotovosti'), Tab(text: 'Uzávěrky')],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddMovementDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Přidat pohyb'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showClosureDialog,
                  icon: const Icon(Icons.lock_clock_rounded, size: 16),
                  label: const Text('Uzávěrka'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMovementsTab(), _buildClosuresTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsTab() {
    return StreamBuilder<List<CashMovement>>(
      stream: _fs.cashMovementsStream(),
      builder: (context, snapshot) {
        final movements = snapshot.data ?? [];
        if (movements.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Žádné pohyby hotovosti',
            subtitle: 'Přidejte první pohyb hotovosti',
          );
        }

        double balance = 0;
        for (final m in movements.reversed) {
          balance += m.type.isPositive ? m.amount : -m.amount;
        }

        return AdminContent(
          children: [
            Wrap(
              spacing: AT.cardGap,
              runSpacing: AT.cardGap,
              children: [
                AdminKpiCard(
                  value: CurrencyFormatter.format(_totalCashRevenue),
                  label: 'Hotovost z tržeb',
                  icon: Icons.point_of_sale_rounded,
                  accentColor: AppColors.success,
                ),
                AdminKpiCard(
                  value: CurrencyFormatter.format(balance),
                  label: 'Saldo pohybů',
                  icon: Icons.swap_vert_rounded,
                  accentColor: balance >= 0 ? AppColors.info : AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: AT.cardGap),
            AdminCardSection(
              title: 'Pohyby',
              children: movements.asMap().entries.map((e) {
                final m = e.value;
                final isPositive = m.type.isPositive;
                return AdminListRow(
                  leading: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      size: 16,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                  title: m.type.title,
                  subtitle: m.note ?? _df.format(m.createdAt),
                  value: '${isPositive ? '+' : '−'} ${CurrencyFormatter.format(m.amount)}',
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 16, color: AT.ink3),
                    onPressed: () => _fs.deleteCashMovement(m.id),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  showDivider: e.key < movements.length - 1,
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClosuresTab() {
    return StreamBuilder<List<DayClosure>>(
      stream: _fs.closuresStream(),
      builder: (context, snapshot) {
        final closures = snapshot.data ?? [];
        if (closures.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.lock_clock_rounded,
            title: 'Žádné uzávěrky',
            subtitle: 'Proveďte první uzávěrku dne',
          );
        }
        final df = DateFormat('dd.MM.yyyy');
        final tf = DateFormat('HH:mm');
        return AdminContent(
          children: [
            AdminCardSection(
              title: 'Historie uzávěrek',
              children: closures.asMap().entries.map((e) {
                final c = e.value;
                return AdminListRow(
                  leading: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AT.indigo.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, size: 16, color: AT.indigo),
                  ),
                  title: 'Uzávěrka ${df.format(c.closedAt)}',
                  subtitle: '${tf.format(c.openedAt)} – ${tf.format(c.closedAt)}  ·  ${c.paymentCount} plateb',
                  value: CurrencyFormatter.format(c.totalRevenue),
                  showDivider: e.key < closures.length - 1,
                );
              }).toList(),
            ),
          ],
        );
      },
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
                items: [CashMovementType.income, CashMovementType.expense]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.title))).toList(),
                onChanged: (v) => setS(() => selectedType = v!),
                decoration: const InputDecoration(labelText: 'Typ pohybu'),
              ),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Částka', suffixText: 'Kč')),
              const SizedBox(height: 12),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Poznámka')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                if (amount == null || amount <= 0) return;
                _fs.addCashMovement(CashMovement(id: const Uuid().v4(), type: selectedType, amount: amount, note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null));
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
    final totalCash = widget.payments.where((p) => p.method == PaymentMethod.cash).fold(0.0, (s, p) => s + p.amount);
    final totalCard = widget.payments.where((p) => p.method == PaymentMethod.card).fold(0.0, (s, p) => s + p.amount);
    final totalTips = widget.payments.fold(0.0, (s, p) => s + p.tip);
    final totalRevenue = widget.payments.fold(0.0, (s, p) => s + p.totalWithTip);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provést uzávěrku'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...[
                ['Celkové tržby', CurrencyFormatter.format(totalRevenue)],
                ['Hotovost',       CurrencyFormatter.format(totalCash)],
                ['Karta',          CurrencyFormatter.format(totalCard)],
                ['Spropitné',      CurrencyFormatter.format(totalTips)],
                ['Počet plateb',   '${widget.payments.length}'],
              ].map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(row[0], style: AT.rowSub)),
                  Text(row[1], style: AT.rowTitle),
                ]),
              )),
              const Divider(height: 24),
              TextField(controller: openingCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Počáteční stav (Kč)', suffixText: 'Kč')),
              const SizedBox(height: 12),
              TextField(controller: closingCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Skutečný stav (Kč)', suffixText: 'Kč')),
              const SizedBox(height: 12),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Poznámka')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              final now = DateTime.now();
              _fs.addClosure(DayClosure(
                id: const Uuid().v4(),
                openedAt: now.subtract(const Duration(hours: 8)),
                closedAt: now,
                openingCash: double.tryParse(openingCtrl.text.replaceAll(',', '.')) ?? 0,
                closingCash: double.tryParse(closingCtrl.text.replaceAll(',', '.')) ?? 0,
                totalRevenue: totalRevenue, totalCash: totalCash, totalCard: totalCard,
                totalTips: totalTips, paymentCount: widget.payments.length,
                note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uzávěrka provedena')));
            },
            child: const Text('Provést uzávěrku'),
          ),
        ],
      ),
    );
  }
}
