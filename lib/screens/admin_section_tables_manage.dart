import 'package:flutter/material.dart';

import '../models/table_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class AdminSectionTablesManage extends StatelessWidget {
  final List<TableModel> tables;

  const AdminSectionTablesManage({super.key, required this.tables});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.lg),
          color: AppColors.background,
          child: Row(
            children: [
              Text('Správa stolů',
                  style: AppTypography.h2.copyWith(color: AppColors.textPrimary)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showTableDialog(context, fs, null, tables),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Přidat stůl'),
              ),
            ],
          ),
        ),
        Expanded(
          child: tables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.table_restaurant_outlined,
                          size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: Spacing.sm),
                      Text('Žádné stoly',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textTertiary)),
                      const SizedBox(height: Spacing.sm),
                      ElevatedButton(
                        onPressed: () =>
                            _showTableDialog(context, fs, null, tables),
                        child: const Text('Přidat první stůl'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(Spacing.md),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: Spacing.sm,
                    mainAxisSpacing: Spacing.sm,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (_, i) =>
                      _tableCard(context, fs, tables[i], tables),
                ),
        ),
      ],
    );
  }

  Widget _tableCard(BuildContext context, FirestoreService fs,
      TableModel table, List<TableModel> allTables) {
    final hasOrder = table.currentOrder != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasOrder ? AppColors.statusActive : AppColors.border,
          width: hasOrder ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant,
            size: 36,
            color: hasOrder ? AppColors.statusActive : AppColors.textTertiary,
          ),
          const SizedBox(height: Spacing.xs),
          Text('Stůl ${table.number}',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.textPrimary)),
          Text(table.status.title,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: Spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                onPressed: () =>
                    _showTableDialog(context, fs, table, allTables),
                tooltip: 'Upravit',
              ),
              if (!hasOrder)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, fs, table),
                  tooltip: 'Smazat',
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTableDialog(BuildContext context, FirestoreService fs,
      TableModel? existing, List<TableModel> allTables) {
    final numberCtrl = TextEditingController(
        text: existing?.number.toString() ?? '');
    var status = existing?.status ?? TableStatus.free;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Nový stůl' : 'Upravit stůl'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Číslo stolu'),
              ),
              const SizedBox(height: Spacing.sm),
              DropdownButtonFormField<TableStatus>(
                value: status,
                decoration:
                    const InputDecoration(labelText: 'Výchozí stav'),
                items: TableStatus.values
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.title)))
                    .toList(),
                onChanged: (v) => setS(() => status = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () {
                final num = int.tryParse(numberCtrl.text);
                if (num == null) return;
                // Check duplicate
                final isDuplicate = allTables.any((t) =>
                    t.number == num && t.id != existing?.id);
                if (isDuplicate) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Stůl s tímto číslem již existuje')),
                  );
                  return;
                }
                final table = TableModel(
                  id: existing?.id ?? 'table_$num',
                  number: num,
                  status: status,
                );
                fs.setTable(table);
                Navigator.pop(ctx);
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, FirestoreService fs, TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat stůl?'),
        content: Text(
            'Opravdu chcete smazat Stůl ${table.number}? Tato akce je nevratná.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              fs.deleteTable(table.id);
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
}

