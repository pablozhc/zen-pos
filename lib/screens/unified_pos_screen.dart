import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../viewmodels/tables_viewmodel.dart';
import '../viewmodels/products_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/product_model.dart';
import '../models/payment_model.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';
import '../models/addon_model.dart';
import '../utils/currency_formatter.dart';
import '../services/printer_service.dart';
import 'payment_screen.dart';
import 'admin_login_screen.dart';

// ── iOS system color tokens ──────────────────────────────────────────────────
const _bg       = Color(0xFFF2F2F7);
const _grouped  = Color(0xFFE5E5EA);
const _card     = Color(0xFFFFFFFF);
const _sep      = Color(0xFFC6C6C8);
const _sepThin  = Color(0xFFD1D1D6);
const _label1   = Color(0xFF1C1C1E);
const _label2   = Color(0xFF6C6C70);
const _label3   = Color(0xFF8E8E93);
const _label4   = Color(0xFFAEAEB2);
const _zen      = Color(0xFFE8445A);
const _zenSoft  = Color(0x1FE8445A);
const _zenDeep  = Color(0xFFD03348);
const _blue     = Color(0xFF007AFF);
const _green    = Color(0xFF34C759);
const _orange   = Color(0xFFFF9500);

enum _POSView { tables, ordering }

class UnifiedPOSScreen extends StatefulWidget {
  const UnifiedPOSScreen({super.key});
  @override
  State<UnifiedPOSScreen> createState() => _UnifiedPOSScreenState();
}

class _UnifiedPOSScreenState extends State<UnifiedPOSScreen> {
  _POSView _view = _POSView.tables;
  int? _selectedTable;
  String? _selectedCategoryId;

  void _selectTable(int number, BuildContext ctx) {
    final tablesVM = ctx.read<TablesViewModel>();
    final table = tablesVM.getTableByNumber(number);
    if (table == null) return;
    if (table.status == TableStatus.free) {
      _showPersonCountDialog(ctx, tablesVM, number);
    } else {
      setState(() {
        _selectedTable = number;
        _view = _POSView.ordering;
      });
    }
  }

  void _showPersonCountDialog(BuildContext ctx, TablesViewModel tablesVM, int tableNumber) {
    int count = 2;
    showDialog(
      context: ctx,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setS) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Stůl $tableNumber',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _label1)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Počet hostů', style: TextStyle(fontSize: 15, color: _label2)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _stepperButton(Icons.remove, count > 1 ? () => setS(() => count--) : null),
              const SizedBox(width: 24),
              Text('$count', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: _label1)),
              const SizedBox(width: 24),
              _stepperButton(Icons.add, () => setS(() => count++)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [2, 3, 4, 5, 6, 8].map((n) =>
              GestureDetector(
                onTap: () => setS(() => count = n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: count == n ? _zen : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$n', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500,
                    color: count == n ? Colors.white : _label1)),
                ),
              )).toList()),
          ]),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(dctx); setState(() { _selectedTable = tableNumber; _view = _POSView.ordering; }); },
              child: const Text('Přeskočit', style: TextStyle(color: _label3))),
            TextButton(
              onPressed: () {
                tablesVM.setPersonCount(tableNumber, count);
                Navigator.pop(dctx);
                setState(() { _selectedTable = tableNumber; _view = _POSView.ordering; });
              },
              child: const Text('Otevřít', style: TextStyle(color: _zen, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFFF2F2F7) : const Color(0xFFF2F2F7).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 20, color: onTap != null ? _zen : _label4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Row(children: [
          _Sidebar(
            selectedView: _view,
            selectedTable: _selectedTable,
            onShowTables: () => setState(() { _view = _POSView.tables; _selectedTable = null; }),
            onShowOrdering: _selectedTable != null ? () => setState(() => _view = _POSView.ordering) : null,
          ),
          Container(width: 0.5, color: _sep),
          Expanded(
            child: _view == _POSView.tables
              ? _TablesView(onTableTap: (n) => _selectTable(n, context))
              : _OrderingView(
                  tableNumber: _selectedTable!,
                  selectedCategoryId: _selectedCategoryId,
                  onCategoryChanged: (id) => setState(() => _selectedCategoryId = id),
                  onTableClosed: () => setState(() { _view = _POSView.tables; _selectedTable = null; }),
                ),
          ),
        ]),
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final _POSView selectedView;
  final int? selectedTable;
  final VoidCallback onShowTables;
  final VoidCallback? onShowOrdering;

  const _Sidebar({
    required this.selectedView,
    required this.selectedTable,
    required this.onShowTables,
    this.onShowOrdering,
  });

  @override
  Widget build(BuildContext context) {
    final tablesVM = context.watch<TablesViewModel>();
    final auth = context.watch<AuthViewModel>();
    final occupied = tablesVM.activeTables.length;
    final total = tablesVM.allTables.length;

    return Container(
      width: 240,
      color: _card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Logo
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: _zen, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('Z',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
            ),
            const SizedBox(width: 10),
            const Text('Zen POS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _label1,
                    letterSpacing: -0.3)),
          ]),
        ),
        Container(height: 0.5, color: _sep),
        const SizedBox(height: 8),

        // Nav
        _sbSection('Service'),
        _sbItem(context, icon: Icons.grid_view_rounded, label: 'Orders',
            badge: tablesVM.activeTables.fold(0, (s, t) => s + (t.currentOrder?.items.length ?? 0)).toString(),
            active: selectedView == _POSView.ordering && selectedTable != null,
            onTap: onShowOrdering),
        _sbItem(context, icon: Icons.table_restaurant_outlined, label: 'Tables',
            badge: '$occupied/$total',
            active: selectedView == _POSView.tables,
            onTap: onShowTables),

        const SizedBox(height: 4),
        _sbSection('Today'),
        _sbItem(context, icon: Icons.bar_chart_rounded, label: 'Shift report',
            active: false,
            onTap: () {}),
        _sbItem(context, icon: Icons.account_balance_wallet_outlined, label: 'Cash drawer',
            active: false,
            onTap: () {}),

        const Spacer(),
        Container(height: 0.5, color: _sep),

        // User
        if (auth.currentUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: _zenSoft, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(
                  auth.currentUser!.name.isNotEmpty ? auth.currentUser!.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: _zen, fontSize: 13, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(auth.currentUser!.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _label1),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
            ]),
          ),

        // Logout
        InkWell(
          onTap: () {
            context.read<AuthViewModel>().logout();
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
          },
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(children: [
              Icon(Icons.logout_rounded, size: 14, color: _label4),
              SizedBox(width: 6),
              Text('Sign out', style: TextStyle(fontSize: 12, color: _label4)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sbSection(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: _label3, letterSpacing: 0.5)),
  );

  Widget _sbItem(BuildContext context, {
    required IconData icon,
    required String label,
    String? badge,
    required bool active,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _zenSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 16,
              color: active ? _zenDeep : (onTap != null ? _label2 : _label4)),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
              fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? _zenDeep : (onTap != null ? _label1 : _label4))),
          const Spacer(),
          if (badge != null && badge != '0')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: active ? _zen.withValues(alpha: 0.2) : const Color(0xFFEEEEF0),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(badge, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: active ? _zenDeep : _label3)),
            ),
        ]),
      ),
    );
  }
}

// ── Tables View ───────────────────────────────────────────────────────────────

class _TablesView extends StatelessWidget {
  final void Function(int) onTableTap;
  const _TablesView({required this.onTableTap});

  @override
  Widget build(BuildContext context) {
    final tablesVM = context.watch<TablesViewModel>();
    final tables = tablesVM.allTables;
    final todayRevenue = tablesVM.todayCompletedRevenue;
    final covers = tablesVM.todayPayments.fold(0, (s, p) => s + p.personCount);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Navbar
      Container(
        height: 56, color: _card,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(children: [
          const Text('Tables',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _label1,
                  letterSpacing: -0.4)),
          const SizedBox(width: 12),
          Text('${tablesVM.activeTables.length}/${tables.length} occupied',
              style: const TextStyle(fontSize: 13, color: _label3)),
        ]),
      ),
      Container(height: 0.5, color: _sep),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Stats row
            Row(children: [
              _statCard("Today's Sales", CurrencyFormatter.format(todayRevenue)),
              const SizedBox(width: 10),
              _statCard("Covers", '$covers'),
              const SizedBox(width: 10),
              _statCard("Avg ticket", tablesVM.todayPayments.isEmpty ? '—'
                  : CurrencyFormatter.format(todayRevenue / tablesVM.todayPayments.length)),
              const SizedBox(width: 10),
              _statCard("Open tables", '${tablesVM.activeTables.length}',
                  accent: tablesVM.activeTables.isNotEmpty),
            ]),
            const SizedBox(height: 20),

            // Table grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: tables.length,
              itemBuilder: (ctx, i) => _TableCard(table: tables[i], onTap: () => onTableTap(tables[i].number)),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _statCard(String label, String value, {bool accent = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _sepThin, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: _label3, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: accent ? _zen : _label1)),
        ]),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;
  const _TableCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = table.status == TableStatus.occupied;
    final needsPayment = isActive && (table.elapsedMinutes ?? 0) > 60;

    Color statusColor;
    if (!isActive) statusColor = _label4;
    else if (needsPayment) statusColor = _orange;
    else statusColor = _zen;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? _card : _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? _zen.withValues(alpha: 0.3) : _sepThin,
            width: isActive ? 1 : 0.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SizedBox(),
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${table.number}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                    letterSpacing: -0.5, color: _label1)),
            Text(
              isActive
                ? '${table.currentOrder?.personCount ?? 1}p · ${table.elapsedMinutes}m'
                : 'Empty',
              style: const TextStyle(fontSize: 11, color: _label3)),
          ]),
          if (isActive)
            Text(CurrencyFormatter.format(table.displayAmount),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    letterSpacing: -0.3, color: _label1,
                    fontFeatures: [FontFeature.tabularFigures()]))
          else
            const Text('Tap to seat',
                style: TextStyle(fontSize: 11, color: _label4)),
        ]),
      ),
    );
  }
}

// ── Ordering View (3-col: sidebar already rendered, here = product grid + receipt) ─

class _OrderingView extends StatefulWidget {
  final int tableNumber;
  final String? selectedCategoryId;
  final void Function(String?) onCategoryChanged;
  final VoidCallback onTableClosed;

  const _OrderingView({
    required this.tableNumber,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onTableClosed,
  });

  @override
  State<_OrderingView> createState() => _OrderingViewState();
}

class _OrderingViewState extends State<_OrderingView> {
  @override
  Widget build(BuildContext context) {
    final productsVM = context.watch<ProductsViewModel>();
    final tablesVM = context.watch<TablesViewModel>();
    final table = tablesVM.getTableByNumber(widget.tableNumber);
    if (table == null) return const SizedBox();

    final categories = productsVM.categories;
    final activeCatId = widget.selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : null);
    final products = activeCatId != null
        ? productsVM.getProductsByCategory(activeCatId)
        : <Product>[];

    return Row(children: [
      // ── Product area ──
      Expanded(
        child: Column(children: [
          // Navbar
          Container(
            height: 56, color: _card,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Column(mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Table ${widget.tableNumber}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                        color: _label1, letterSpacing: -0.4)),
                if (table.currentOrder != null)
                  Text('${table.currentOrder!.personCount} guests · ${table.elapsedMinutes}m',
                      style: const TextStyle(fontSize: 12, color: _label3)),
              ]),
              const Spacer(),
              // Discount button
              if (table.currentOrder != null)
                _navAction('Discount', Icons.local_offer_outlined, () =>
                    _showDiscountDialog(context, tablesVM, table)),
            ]),
          ),
          Container(height: 0.5, color: _sep),

          // Category chips
          if (categories.isNotEmpty)
            Container(
              height: 52, color: _card,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final isActive = cat.id == activeCatId;
                  return GestureDetector(
                    onTap: () => widget.onCategoryChanged(cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? _zen : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${cat.emoji} ${cat.title}',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: isActive ? Colors.white : _label2)),
                    ),
                  );
                },
              ),
            ),
          Container(height: 0.5, color: _sep),

          // Product tile grid
          Expanded(
            child: products.isEmpty
              ? const Center(child: Text('Žádné produkty',
                  style: TextStyle(fontSize: 15, color: _label3)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 140,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) {
                    final product = products[i];
                    final orderCount = table.currentOrder?.items
                        .where((it) => it.product.id == product.id && !it.isStorno)
                        .fold(0, (s, it) => s + it.quantity) ?? 0;
                    return _ProductTile(
                      product: product,
                      orderCount: orderCount,
                      onTap: () => _showItemDetail(context, tablesVM, product, table),
                    );
                  },
                ),
          ),
        ]),
      ),

      // ── Receipt panel ──
      Container(width: 0.5, color: _sep),
      _ReceiptPanel(
        table: table,
        onStornoItem: (itemId) => _showStornoDialog(context, tablesVM, table, itemId),
        onCharge: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PaymentScreen(table: table))),
        onCloseTable: widget.onTableClosed,
      ),
    ]);
  }

  Widget _navAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: _label2),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: _label2, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  void _showItemDetail(BuildContext ctx, TablesViewModel tablesVM,
      Product product, TableModel table) {
    showDialog(
      context: ctx,
      builder: (dctx) => _ItemDetailDialog(
        product: product,
        onAdd: (qty, addons, note) {
          for (int i = 0; i < qty; i++) {
            tablesVM.addProductToTable(table.number, product,
                addons: addons, note: note);
          }
        },
      ),
    );
  }

  void _showDiscountDialog(BuildContext ctx, TablesViewModel tablesVM, TableModel table) {
    final order = table.currentOrder;
    if (order == null) return;
    final amountCtrl = TextEditingController(
        text: order.discountAmount > 0 ? order.discountAmount.toStringAsFixed(0) : '');
    final reasonCtrl = TextEditingController(text: order.discountReason ?? '');
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sleva na účet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _label1)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amountCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Výše slevy', suffixText: 'Kč')),
          const SizedBox(height: 8),
          TextField(controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Důvod')),
        ]),
        actions: [
          if (order.discountAmount > 0)
            TextButton(onPressed: () { tablesVM.setDiscount(table.number, 0, null); Navigator.pop(dctx); },
                child: const Text('Odebrat', style: TextStyle(color: _label3))),
          TextButton(onPressed: () => Navigator.pop(dctx),
              child: const Text('Zrušit', style: TextStyle(color: _label3))),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
              tablesVM.setDiscount(table.number, amt,
                  reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null);
              Navigator.pop(dctx);
            },
            child: const Text('Uložit', style: TextStyle(color: _zen, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showStornoDialog(BuildContext ctx, TablesViewModel tablesVM,
      TableModel table, String itemId) {
    final item = table.currentOrder?.items.firstWhere((i) => i.id == itemId);
    if (item == null) return;
    final reasonCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Storno položky',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _label1)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${item.product.name} ×${item.quantity}',
              style: const TextStyle(fontSize: 15, color: _label2)),
          const SizedBox(height: 8),
          TextField(controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Důvod storna (volitelné)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx),
              child: const Text('Zrušit', style: TextStyle(color: _label3))),
          TextButton(
            onPressed: () {
              tablesVM.stornoItem(table.number, itemId,
                  reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null);
              Navigator.pop(dctx);
            },
            child: const Text('Stornovat', style: TextStyle(color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ── Product Tile ──────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final Product product;
  final int orderCount;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.orderCount, required this.onTap});

  // Deterministic color swatch from product id
  Color _swatchColor() {
    final hash = product.id.hashCode;
    final hues = [200, 220, 340, 30, 150, 270, 60, 170];
    final hue = hues[hash.abs() % hues.length];
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.55).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final swatch = _swatchColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _sepThin, width: 0.5),
        ),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Color swatch
            Container(
              height: 36, width: double.infinity,
              decoration: BoxDecoration(
                color: swatch.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11), topRight: Radius.circular(11)),
              ),
              child: Center(child: Text(product.emoji,
                  style: const TextStyle(fontSize: 18))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
              child: Text(product.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: _label1, height: 1.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(CurrencyFormatter.format(product.price),
                  style: const TextStyle(fontSize: 11, color: _label3,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ),
          ]),
          // Quantity badge
          if (orderCount > 0)
            Positioned(
              top: 5, right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: _zen,
                    borderRadius: BorderRadius.circular(99)),
                child: Text('$orderCount',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Item Detail Dialog ────────────────────────────────────────────────────────

class _ItemDetailDialog extends StatefulWidget {
  final Product product;
  final void Function(int qty, List<SelectedAddon> addons, String? note) onAdd;

  const _ItemDetailDialog({required this.product, required this.onAdd});

  @override
  State<_ItemDetailDialog> createState() => _ItemDetailDialogState();
}

class _ItemDetailDialogState extends State<_ItemDetailDialog> {
  int _qty = 1;
  String? _note;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _card,
      elevation: 24,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.product.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: _label1, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text(widget.product.description.isNotEmpty
                    ? widget.product.description : 'Bez popisu',
                    style: const TextStyle(fontSize: 13, color: _label3)),
              ])),
              Text(CurrencyFormatter.format(widget.product.price),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: _label1, letterSpacing: -0.4,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ]),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: _sepThin),
            ),

            // Note
            const Align(alignment: Alignment.centerLeft,
              child: Text('NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: _label3, letterSpacing: 0.6))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration.collapsed(
                    hintText: 'Extra horké, bez cukru...',
                    hintStyle: TextStyle(color: _label4, fontSize: 14)),
                style: const TextStyle(fontSize: 14, color: _label1),
                onChanged: (v) => _note = v.isEmpty ? null : v,
              ),
            ),
            const SizedBox(height: 20),

            // Qty + Add button
            Row(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  _qtyButton(Icons.remove, _qty > 1 ? () => setState(() => _qty--) : null),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('$_qty', style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w600, color: _label1)),
                  ),
                  _qtyButton(Icons.add, () => setState(() => _qty++)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onAdd(_qty, [], _note);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _zen, borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text(
                        'Add · ${CurrencyFormatter.format(widget.product.price * _qty)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                            color: Colors.white, letterSpacing: -0.2)),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: onTap != null ? _card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? _label1 : _label4),
      ),
    );
  }
}

// ── Receipt Panel ─────────────────────────────────────────────────────────────

class _ReceiptPanel extends StatelessWidget {
  final TableModel table;
  final void Function(String) onStornoItem;
  final VoidCallback onCharge;
  final VoidCallback onCloseTable;

  const _ReceiptPanel({
    required this.table,
    required this.onStornoItem,
    required this.onCharge,
    required this.onCloseTable,
  });

  @override
  Widget build(BuildContext context) {
    final order = table.currentOrder;
    final total = order?.total ?? 0;
    final hasItems = order != null && order.items.isNotEmpty;

    return Container(
      width: 300,
      color: _card,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _sep, width: 0.5))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Table ${table.number}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                      color: _label1, letterSpacing: -0.4)),
              if (order != null)
                Text('${order.personCount} guests · ${context.read<AuthViewModel>().currentUser?.name ?? ''}',
                    style: const TextStyle(fontSize: 12, color: _label3)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _zenSoft, borderRadius: BorderRadius.circular(99)),
              child: const Text('● Open',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _zenDeep)),
            ),
          ]),
        ),

        // Order items
        Expanded(
          child: hasItems
            ? ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: order!.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _sepThin, indent: 16, endIndent: 16),
                itemBuilder: (ctx, i) {
                  final item = order.items[i];
                  return GestureDetector(
                    onLongPress: () => !item.isStorno ? onStornoItem(item.id) : null,
                    child: Opacity(
                      opacity: item.isStorno ? 0.4 : 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${item.quantity}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: _zen)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.product.name,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                                    color: _label1,
                                    decoration: item.isStorno ? TextDecoration.lineThrough : null)),
                            if (item.note != null)
                              Text(item.note!, style: const TextStyle(fontSize: 11, color: _label3)),
                            if (item.selectedAddons.isNotEmpty)
                              Text(item.selectedAddons.map((a) => a.optionName).join(', '),
                                  style: const TextStyle(fontSize: 11, color: _label3)),
                          ])),
                          Text(CurrencyFormatter.format(item.totalPrice),
                              style: const TextStyle(fontSize: 14, color: _label1,
                                  fontFeatures: [FontFeature.tabularFigures()])),
                        ]),
                      ),
                    ),
                  );
                },
              )
            : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_outlined, size: 40, color: _label4),
                SizedBox(height: 8),
                Text('No items yet', style: TextStyle(fontSize: 14, color: _label3)),
              ])),
        ),

        // Totals + pay
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _sep, width: 0.5))),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (hasItems) ...[
              _totalRow('Subtotal', order!.subtotal),
              const SizedBox(height: 4),
              _totalRow('VAT 21%', order.vat),
              if (order.discountAmount > 0) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Discount', style: TextStyle(fontSize: 13, color: _orange)),
                  Text('- ${CurrencyFormatter.format(order.discountAmount)}',
                      style: const TextStyle(fontSize: 13, color: _orange,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ]),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _sepThin)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: _label1)),
                Text(CurrencyFormatter.format(total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: _label1, fontFeatures: [FontFeature.tabularFigures()])),
              ]),
              const SizedBox(height: 14),
            ],
            // Charge button
            GestureDetector(
              onTap: hasItems ? onCharge : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: hasItems ? _zen : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Charge', style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600,
                      color: hasItems ? Colors.white : _label4, letterSpacing: -0.3)),
                  if (hasItems) ...[
                    const SizedBox(width: 8),
                    Text(CurrencyFormatter.format(total),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _totalRow(String label, double value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: _label3)),
      Text(CurrencyFormatter.format(value),
          style: const TextStyle(fontSize: 13, color: _label2,
              fontFeatures: [FontFeature.tabularFigures()])),
    ]);
  }
}
