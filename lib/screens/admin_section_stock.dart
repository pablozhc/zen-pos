import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';

class AdminSectionStock extends StatefulWidget {
  const AdminSectionStock({super.key});

  @override
  State<AdminSectionStock> createState() => _AdminSectionStockState();
}

class _AdminSectionStockState extends State<AdminSectionStock>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

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
              Text('Sklad',
                  style: AppTypography.h2
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: Spacing.sm),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Skladové karty'),
                  Tab(text: 'Naskladnění'),
                  Tab(text: 'Inventury'),
                  Tab(text: 'Odpisy'),
                  Tab(text: 'Dodavatelé'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildStockItemsTab(),
              _buildReceivingTab(),
              _buildInventoriesTab(),
              _buildWriteOffsTab(),
              _buildSuppliersTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Skladové karty ──

  Widget _buildStockItemsTab() {
    return StreamBuilder<List<StockItem>>(
      stream: _fs.stockItemsStream(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Text('${items.length} karet',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showStockItemDialog(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nová karta'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _emptyState('Žádné skladové karty', Icons.inventory_2_outlined,
                      () => _showStockItemDialog(context, null))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) =>
                          _stockItemRow(context, items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _stockItemRow(BuildContext context, StockItem item) {
    final isLow = item.isLowStock;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isLow
              ? AppColors.error.withValues(alpha: 0.12)
              : AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isLow ? Icons.warning_amber : Icons.inventory_2,
          color: isLow ? AppColors.error : AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(item.name,
          style: AppTypography.labelMedium
              .copyWith(color: AppColors.textPrimary)),
      subtitle: Text(
          '${item.currentStock.toStringAsFixed(1)} ${item.unit.label}'
          '${item.minStock != null ? ' (min: ${item.minStock!.toStringAsFixed(1)})' : ''}',
          style: AppTypography.caption.copyWith(
              color: isLow ? AppColors.error : AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.costPrice > 0)
            Text(CurrencyFormatter.format(item.costPrice),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: Spacing.sm),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
            onPressed: () => _showStockItemDialog(context, item),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            onPressed: () => _confirmDeleteItem(context, item),
          ),
        ],
      ),
    );
  }

  void _showStockItemDialog(BuildContext context, StockItem? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final costCtrl = TextEditingController(
        text: existing?.costPrice.toStringAsFixed(2) ?? '');
    final minCtrl = TextEditingController(
        text: existing?.minStock?.toStringAsFixed(1) ?? '');
    var unit = existing?.unit ?? StockUnit.piece;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
              existing == null ? 'Nová skladová karta' : 'Upravit kartu'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Název'),
                ),
                const SizedBox(height: Spacing.sm),
                DropdownButtonFormField<StockUnit>(
                  value: unit,
                  decoration: const InputDecoration(labelText: 'Jednotka'),
                  items: StockUnit.values
                      .map((u) => DropdownMenuItem(
                          value: u, child: Text(u.label)))
                      .toList(),
                  onChanged: (v) => setS(() => unit = v!),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: costCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Nákupní cena / jednotka',
                      suffixText: 'Kč'),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: minCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Minimální zásoba (upozornění)'),
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
                if (nameCtrl.text.trim().isEmpty) return;
                final item = StockItem(
                  id: existing?.id ?? const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  unit: unit,
                  currentStock: existing?.currentStock ?? 0,
                  costPrice:
                      double.tryParse(costCtrl.text.replaceAll(',', '.')) ??
                          0,
                  minStock: minCtrl.text.isNotEmpty
                      ? double.tryParse(minCtrl.text.replaceAll(',', '.'))
                      : null,
                );
                _fs.setStockItem(item);
                Navigator.pop(ctx);
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteItem(BuildContext context, StockItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat skladovou kartu?'),
        content: Text(
            'Opravdu chcete smazat "${item.name}"? Odstraní se i pohyby na skladu.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              _fs.deleteStockItem(item.id);
              Navigator.pop(ctx);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
  }

  // ── Naskladnění ──

  Widget _buildReceivingTab() {
    return StreamBuilder<List<StockTransaction>>(
      stream: _fs.stockTransactionsStream(
          type: StockTransactionType.receiving),
      builder: (context, snapshot) {
        final txs = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Text('${txs.length} naskladnění',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showTransactionDialog(
                            context, StockTransactionType.receiving),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nové naskladnění'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: txs.isEmpty
                  ? _emptyState(
                      'Žádná naskladnění',
                      Icons.local_shipping_outlined,
                      () => _showTransactionDialog(
                          context, StockTransactionType.receiving))
                  : _transactionList(txs),
            ),
          ],
        );
      },
    );
  }

  // ── Odpisy ──

  Widget _buildWriteOffsTab() {
    return StreamBuilder<List<StockTransaction>>(
      stream:
          _fs.stockTransactionsStream(type: StockTransactionType.writeOff),
      builder: (context, snapshot) {
        final txs = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Text('${txs.length} odpisů',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showTransactionDialog(
                        context, StockTransactionType.writeOff),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nový odpis'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: txs.isEmpty
                  ? _emptyState(
                      'Žádné odpisy',
                      Icons.remove_circle_outline,
                      () => _showTransactionDialog(
                          context, StockTransactionType.writeOff))
                  : _transactionList(txs),
            ),
          ],
        );
      },
    );
  }

  Widget _transactionList(List<StockTransaction> txs) {
    final df = DateFormat('dd.MM.yyyy HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      itemCount: txs.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) {
        final tx = txs[i];
        final isIn = tx.type == StockTransactionType.receiving ||
            tx.type == StockTransactionType.inventoryCorrection;
        return ListTile(
          leading: Icon(
            isIn ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIn ? AppColors.success : AppColors.error,
          ),
          title: Text(tx.stockItemName,
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textPrimary)),
          subtitle: Text(df.format(tx.createdAt),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${isIn ? '+' : '-'}${tx.quantity}',
                style: AppTypography.labelMedium
                    .copyWith(color: isIn ? AppColors.success : AppColors.error),
              ),
              if (tx.totalValue > 0)
                Text(CurrencyFormatter.format(tx.totalValue),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }

  void _showTransactionDialog(
      BuildContext context, StockTransactionType type) {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    StockItem? selectedItem;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(type.title),
          content: SizedBox(
            width: 400,
            child: StreamBuilder<List<StockItem>>(
              stream: _fs.stockItemsStream(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<StockItem>(
                      value: selectedItem,
                      decoration:
                          const InputDecoration(labelText: 'Skladová karta'),
                      items: items
                          .map((item) => DropdownMenuItem(
                              value: item, child: Text(item.name)))
                          .toList(),
                      onChanged: (v) => setS(() => selectedItem = v),
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Množství',
                        suffixText: selectedItem?.unit.label,
                      ),
                    ),
                    if (type == StockTransactionType.receiving) ...[
                      const SizedBox(height: Spacing.sm),
                      TextField(
                        controller: priceCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Cena/jednotka', suffixText: 'Kč'),
                      ),
                    ],
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: noteCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Poznámka'),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () {
                if (selectedItem == null) return;
                final qty = double.tryParse(
                    qtyCtrl.text.replaceAll(',', '.'));
                if (qty == null || qty <= 0) return;
                final tx = StockTransaction(
                  id: const Uuid().v4(),
                  type: type,
                  stockItemId: selectedItem!.id,
                  stockItemName: selectedItem!.name,
                  quantity: qty,
                  unitPrice: double.tryParse(
                      priceCtrl.text.replaceAll(',', '.')),
                  note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
                );
                _fs.addStockTransaction(tx);
                Navigator.pop(ctx);
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Inventury ──

  Widget _buildInventoriesTab() {
    return StreamBuilder<List<Inventory>>(
      stream: _fs.inventoriesStream(),
      builder: (context, snapshot) {
        final inventories = snapshot.data ?? [];
        final df = DateFormat('dd.MM.yyyy HH:mm');
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Text('${inventories.length} inventur',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _createInventory(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nová inventura'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: inventories.isEmpty
                  ? _emptyState('Žádné inventury', Icons.fact_check_outlined,
                      () => _createInventory(context))
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: Spacing.md),
                      itemCount: inventories.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) {
                        final inv = inventories[i];
                        return ListTile(
                          leading: _statusIcon(inv.status),
                          title: Text(
                              'Inventura ${df.format(inv.createdAt)}',
                              style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textPrimary)),
                          subtitle: Text(
                              '${inv.items.length} položek • ${inv.status.name}',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary)),
                          trailing: inv.status == InventoryStatus.draft
                              ? TextButton(
                                  onPressed: () =>
                                      _showInventoryDetail(context, inv),
                                  child: const Text('Dokončit'))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _statusIcon(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.draft:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.edit, color: AppColors.warning, size: 18),
        );
      case InventoryStatus.completed:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.check, color: AppColors.info, size: 18),
        );
      case InventoryStatus.approved:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.verified, color: AppColors.success, size: 18),
        );
    }
  }

  Future<void> _createInventory(BuildContext context) async {
    final items = await _fs.stockItemsStream().first;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Nejdříve přidejte skladové karty')),
      );
      return;
    }
    final inv = Inventory(
      id: const Uuid().v4(),
      items: items
          .map((item) => InventoryItem(
                stockItemId: item.id,
                stockItemName: item.name,
                expectedQuantity: item.currentStock,
                actualQuantity: item.currentStock,
                unit: item.unit,
              ))
          .toList(),
    );
    await _fs.setInventory(inv);
    if (context.mounted) _showInventoryDetail(context, inv);
  }

  void _showInventoryDetail(BuildContext context, Inventory inv) {
    final items = List<InventoryItem>.from(inv.items);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Inventura'),
          content: SizedBox(
            width: 600,
            height: 500,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.stockItemName,
                            style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary)),
                      ),
                      Text(
                          'Oček.: ${item.expectedQuantity.toStringAsFixed(1)} ${item.unit.label}',
                          style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary)),
                      const SizedBox(width: Spacing.sm),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue:
                              item.actualQuantity.toStringAsFixed(1),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: InputDecoration(
                              suffixText: item.unit.label,
                              isDense: true),
                          onChanged: (v) {
                            final qty = double.tryParse(
                                v.replaceAll(',', '.'));
                            if (qty != null) {
                              setS(() => items[i] = InventoryItem(
                                    stockItemId: item.stockItemId,
                                    stockItemName: item.stockItemName,
                                    expectedQuantity: item.expectedQuantity,
                                    actualQuantity: qty,
                                    unit: item.unit,
                                  ));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        _diffText(items[i]),
                        style: AppTypography.caption.copyWith(
                            color: items[i].difference >= 0
                                ? AppColors.success
                                : AppColors.error),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () async {
                final updated = Inventory(
                  id: inv.id,
                  createdAt: inv.createdAt,
                  completedAt: DateTime.now(),
                  status: InventoryStatus.completed,
                  items: items,
                );
                await _fs.setInventory(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Dokončit inventuru'),
            ),
          ],
        ),
      ),
    );
  }

  String _diffText(InventoryItem item) {
    final d = item.difference;
    if (d == 0) return '±0';
    return '${d > 0 ? '+' : ''}${d.toStringAsFixed(1)} ${item.unit.label}';
  }

  // ── Dodavatelé ──

  Widget _buildSuppliersTab() {
    return StreamBuilder<List<Supplier>>(
      stream: _fs.suppliersStream(),
      builder: (context, snapshot) {
        final suppliers = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Text('${suppliers.length} dodavatelů',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showSupplierDialog(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Přidat dodavatele'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: suppliers.isEmpty
                  ? _emptyState('Žádní dodavatelé', Icons.local_shipping_outlined,
                      () => _showSupplierDialog(context, null))
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: Spacing.md),
                      itemCount: suppliers.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) =>
                          _supplierRow(context, suppliers[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _supplierRow(BuildContext context, Supplier s) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.business, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(s.name,
          style:
              AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
      subtitle: Text(
          [s.contactName, s.phone, s.email]
              .where((v) => v != null && v.isNotEmpty)
              .join(' • '),
          style:
              AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
            onPressed: () => _showSupplierDialog(context, s),
          ),
          IconButton(
            icon:
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            onPressed: () => _fs.deleteSupplier(s.id),
          ),
        ],
      ),
    );
  }

  void _showSupplierDialog(BuildContext context, Supplier? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final contactCtrl =
        TextEditingController(text: existing?.contactName ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?.phone ?? '');
    final emailCtrl =
        TextEditingController(text: existing?.email ?? '');
    final addressCtrl =
        TextEditingController(text: existing?.address ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existing == null ? 'Nový dodavatel' : 'Upravit dodavatele'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Název firmy')),
              const SizedBox(height: Spacing.xs),
              TextField(
                  controller: contactCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Kontaktní osoba')),
              const SizedBox(height: Spacing.xs),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefon')),
              const SizedBox(height: Spacing.xs),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: Spacing.xs),
              TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Adresa')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final supplier = Supplier(
                id: existing?.id ?? const Uuid().v4(),
                name: nameCtrl.text.trim(),
                contactName: contactCtrl.text.isNotEmpty
                    ? contactCtrl.text
                    : null,
                phone:
                    phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null,
                email:
                    emailCtrl.text.isNotEmpty ? emailCtrl.text : null,
                address:
                    addressCtrl.text.isNotEmpty ? addressCtrl.text : null,
              );
              _fs.setSupplier(supplier);
              Navigator.pop(ctx);
            },
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _emptyState(String label, IconData icon, VoidCallback onCreate) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: Spacing.sm),
          Text(label,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: Spacing.sm),
          ElevatedButton(onPressed: onCreate, child: const Text('Přidat')),
        ],
      ),
    );
  }
}

