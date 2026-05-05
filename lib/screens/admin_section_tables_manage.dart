import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'admin_widgets.dart';

class AdminSectionTablesManage extends StatelessWidget {
  final List<TableModel> tables;
  const AdminSectionTablesManage({super.key, required this.tables});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Expanded(
      child: Column(
        children: [
          Container(
            color: AT.bg,
            padding: const EdgeInsets.fromLTRB(AT.pagePad, AT.pagePad, AT.pagePad, AT.pagePad),
            child: Row(
              children: [
                Text('${tables.length} stolů', style: AT.rowSub),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showTableDialog(context, fs, null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Přidat stůl'),
                ),
              ],
            ),
          ),
          Expanded(
            child: tables.isEmpty
                ? AdminEmptyState(
                    icon: Icons.table_restaurant_rounded,
                    title: 'Žádné stoly',
                    subtitle: 'Přidejte stoly pro váš provoz',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AT.pagePad),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: AT.cardGap,
                      mainAxisSpacing: AT.cardGap,
                    ),
                    itemCount: tables.length,
                    itemBuilder: (_, i) => _tableCard(context, fs, tables[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tableCard(BuildContext context, FirestoreService fs, TableModel table) {
    final hasOrder = table.currentOrder != null;
    return Container(
      decoration: BoxDecoration(
        color: hasOrder ? AppColors.primary.withValues(alpha: 0.06) : AT.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasOrder ? AppColors.primary.withValues(alpha: 0.3) : AT.border,
          width: hasOrder ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: hasOrder ? AppColors.primary.withValues(alpha: 0.12) : AT.bgWarm,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.table_restaurant_rounded,
              size: 22,
              color: hasOrder ? AppColors.primary : AT.ink3,
            ),
          ),
          const SizedBox(height: 8),
          Text('Stůl ${table.number}', style: AT.cardTitle),
          Text(table.status.title, style: AT.rowSub),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBtn(Icons.edit_rounded, AT.ink3, () => _showTableDialog(context, fs, table)),
              if (!hasOrder)
                _iconBtn(Icons.delete_outline_rounded, AppColors.error, () => _confirmDelete(context, fs, table)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _showTableDialog(BuildContext context, FirestoreService fs, TableModel? existing) {
    final numberCtrl = TextEditingController(text: existing?.number.toString() ?? '');
    var status = existing?.status ?? TableStatus.free;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Nový stůl' : 'Upravit stůl'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numberCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Číslo stolu')),
              const SizedBox(height: 12),
              DropdownButtonFormField<TableStatus>(
                value: status,
                decoration: const InputDecoration(labelText: 'Výchozí stav'),
                items: TableStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.title))).toList(),
                onChanged: (v) => setS(() => status = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () {
                final num = int.tryParse(numberCtrl.text);
                if (num == null) return;
                if (tables.any((t) => t.number == num && t.id != existing?.id)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Stůl s tímto číslem již existuje')));
                  return;
                }
                fs.setTable(TableModel(id: existing?.id ?? 'table_$num', number: num, status: status));
                Navigator.pop(ctx);
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService fs, TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat stůl?'),
        content: Text('Opravdu smazat Stůl ${table.number}? Tato akce je nevratná.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () { fs.deleteTable(table.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
  }
}
