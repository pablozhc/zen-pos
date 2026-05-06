import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/addon_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'admin_widgets.dart';

class AdminSectionAddons extends StatelessWidget {
  final List<ProductCategory> categories;
  final List<Product> products;

  const AdminSectionAddons({super.key, required this.categories, required this.products});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<ProductAddon>>(
      stream: fs.addonsStream(),
      builder: (context, snapshot) {
        final addons = snapshot.data ?? [];
        return Expanded(
          child: Column(
            children: [
              Container(
                color: AT.bg,
                padding: const EdgeInsets.fromLTRB(AT.pagePad, AT.pagePad, AT.pagePad, 12),
                child: Row(
                  children: [
                    Text('Přídavky umožňují přidat k produktu volitelné doplňky.', style: AT.rowSub),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddonDialog(context, fs, null),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nová skupina'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: addons.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Žádné skupiny přídavků',
                        subtitle: 'Vytvořte přídavky jako přílohy, teplotu masa nebo omáčky',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AT.pagePad),
                        itemCount: addons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AT.cardGap),
                        itemBuilder: (_, i) => _addonCard(context, fs, addons[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addonCard(BuildContext context, FirestoreService fs, ProductAddon addon) {
    return Container(
      decoration: AT.card,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AT.rowPadH, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(addon.name, style: AT.cardTitle),
                          const SizedBox(width: 8),
                          if (addon.isRequired) AdminBadge(label: 'Povinné', color: AppColors.error),
                          if (addon.multiSelect) ...[
                            const SizedBox(width: 6),
                            AdminBadge(label: 'Multi', color: AppColors.info),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        addon.productIds.isEmpty && addon.categoryIds.isEmpty
                            ? 'Platí pro všechny produkty'
                            : 'Platí pro ${addon.productIds.length + addon.categoryIds.length} položek',
                        style: AT.rowSub,
                      ),
                    ],
                  ),
                ),
                IconButton(icon: Icon(Icons.edit_rounded, size: 18, color: AT.ink3), onPressed: () => _showAddonDialog(context, fs, addon)),
                IconButton(icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), onPressed: () => _confirmDelete(context, fs, addon)),
              ],
            ),
          ),
          if (addon.options.isNotEmpty) ...[
            const Divider(height: 1, thickness: 0.5, color: AT.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(AT.rowPadH, 10, AT.rowPadH, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: addon.options.map((o) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AT.bgWarm, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    o.extraPrice > 0 ? '${o.name}  +${o.extraPrice.toStringAsFixed(0)} Kč' : o.name,
                    style: AT.rowSub.copyWith(fontSize: 12),
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddonDialog(BuildContext context, FirestoreService fs, ProductAddon? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    bool isRequired = existing?.isRequired ?? false;
    bool multiSelect = existing?.multiSelect ?? false;
    final options = List<AddonOption>.from(existing?.options ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Nový přídavek' : 'Upravit přídavek'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Název skupiny přídavků')),
                  const SizedBox(height: 12),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('Povinný výběr', style: AT.rowTitle), value: isRequired, onChanged: (v) => setS(() => isRequired = v)),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('Více možností najednou', style: AT.rowTitle), value: multiSelect, onChanged: (v) => setS(() => multiSelect = v)),
                  const SizedBox(height: 12),
                  Text('Možnosti', style: AT.sectionLabel),
                  const SizedBox(height: 8),
                  ...options.asMap().entries.map((e) {
                    final i = e.key;
                    final opt = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: TextFormField(initialValue: opt.name, decoration: const InputDecoration(hintText: 'Název možnosti', isDense: true), onChanged: (v) => options[i] = AddonOption(id: opt.id, name: v, extraPrice: opt.extraPrice))),
                          const SizedBox(width: 8),
                          SizedBox(width: 80, child: TextFormField(initialValue: opt.extraPrice > 0 ? opt.extraPrice.toStringAsFixed(0) : '', decoration: const InputDecoration(hintText: '+Kč', isDense: true, suffixText: 'Kč'), keyboardType: TextInputType.number, onChanged: (v) => options[i] = AddonOption(id: opt.id, name: opt.name, extraPrice: double.tryParse(v) ?? 0))),
                          IconButton(icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.error), onPressed: () => setS(() => options.removeAt(i))),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setS(() => options.add(AddonOption(id: const Uuid().v4(), name: ''))),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Přidat možnost'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                fs.setAddon(ProductAddon(id: existing?.id ?? const Uuid().v4(), name: nameCtrl.text.trim(), isRequired: isRequired, multiSelect: multiSelect, options: options.where((o) => o.name.isNotEmpty).toList()));
                Navigator.pop(ctx);
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService fs, ProductAddon addon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat přídavek?'),
        content: Text('Opravdu chcete smazat "${addon.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
          ElevatedButton(onPressed: () { fs.deleteAddon(addon.id); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Smazat')),
        ],
      ),
    );
  }
}
