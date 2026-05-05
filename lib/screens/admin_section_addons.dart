import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/addon_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class AdminSectionAddons extends StatelessWidget {
  final List<ProductCategory> categories;
  final List<Product> products;

  const AdminSectionAddons({
    super.key,
    required this.categories,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<ProductAddon>>(
      stream: fs.addonsStream(),
      builder: (context, snapshot) {
        final addons = snapshot.data ?? [];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              color: AppColors.background,
              child: Row(
                children: [
                  Text('Přídavky',
                      style: AppTypography.h2
                          .copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showAddonDialog(context, fs, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nová kategorie přídavků'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, 0, Spacing.lg, Spacing.md),
              color: AppColors.backgroundTertiary,
              child: Row(
                children: [
                  Text(
                    'Přídavky umožňují obsluze přidat k produktu volitelné nebo povinné doplňky (přílohy, teplota masa, omáčky...).',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: addons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: Spacing.sm),
                          Text('Žádné přídavky',
                              style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textTertiary)),
                          const SizedBox(height: Spacing.sm),
                          ElevatedButton(
                            onPressed: () =>
                                _showAddonDialog(context, fs, null),
                            child: const Text('Vytvořit první přídavek'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(Spacing.md),
                      itemCount: addons.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacing.sm),
                      itemBuilder: (_, i) =>
                          _addonCard(context, fs, addons[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _addonCard(
      BuildContext context, FirestoreService fs, ProductAddon addon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(addon.name,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(width: Spacing.sm),
                if (addon.isRequired)
                  _chip('Povinné', AppColors.error),
                if (addon.multiSelect)
                  _chip('Více možností', AppColors.info),
              ],
            ),
            subtitle: Text(
                addon.productIds.isEmpty && addon.categoryIds.isEmpty
                    ? 'Platí pro všechny produkty'
                    : 'Platí pro ${addon.productIds.length + addon.categoryIds.length} položek',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon:
                      Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                  onPressed: () => _showAddonDialog(context, fs, addon),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, fs, addon),
                ),
              ],
            ),
          ),
          if (addon.options.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.xs,
                children: addon.options
                    .map((o) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundTertiary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            o.extraPrice > 0
                                ? '${o.name} (+${o.extraPrice.toStringAsFixed(0)} Kč)'
                                : o.name,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTypography.caption.copyWith(color: color)),
    );
  }

  void _showAddonDialog(
      BuildContext context, FirestoreService fs, ProductAddon? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
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
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Název skupiny přídavků'),
                  ),
                  const SizedBox(height: Spacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Povinný výběr',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    value: isRequired,
                    onChanged: (v) => setS(() => isRequired = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Více možností najednou',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    value: multiSelect,
                    onChanged: (v) => setS(() => multiSelect = v),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text('Možnosti:',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: Spacing.xs),
                  ...options.asMap().entries.map((e) {
                    final i = e.key;
                    final opt = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: opt.name,
                              decoration: const InputDecoration(
                                  hintText: 'Název možnosti',
                                  isDense: true),
                              onChanged: (v) => options[i] =
                                  AddonOption(
                                      id: opt.id,
                                      name: v,
                                      extraPrice: opt.extraPrice),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: opt.extraPrice > 0
                                  ? opt.extraPrice.toStringAsFixed(0)
                                  : '',
                              decoration: const InputDecoration(
                                  hintText: '+Kč',
                                  isDense: true,
                                  suffixText: 'Kč'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => options[i] =
                                  AddonOption(
                                      id: opt.id,
                                      name: opt.name,
                                      extraPrice:
                                          double.tryParse(v) ?? 0),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                size: 18, color: AppColors.error),
                            onPressed: () =>
                                setS(() => options.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setS(() => options.add(AddonOption(
                          id: const Uuid().v4(),
                          name: '',
                        ))),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Přidat možnost'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final addon = ProductAddon(
                  id: existing?.id ?? const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  isRequired: isRequired,
                  multiSelect: multiSelect,
                  options: options
                      .where((o) => o.name.isNotEmpty)
                      .toList(),
                );
                fs.setAddon(addon);
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
      BuildContext context, FirestoreService fs, ProductAddon addon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat přídavek?'),
        content: Text('Opravdu chcete smazat "${addon.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              fs.deleteAddon(addon.id);
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
