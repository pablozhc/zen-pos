import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:uuid/uuid.dart';
import '../models/happy_hour_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class AdminSectionHappyHours extends StatelessWidget {
  final List<ProductCategory> categories;
  final List<Product> products;

  const AdminSectionHappyHours({
    super.key,
    required this.categories,
    required this.products,
  });

  static const _weekdayNames = [
    '', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'
  ];

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<HappyHour>>(
      stream: fs.happyHoursStream(),
      builder: (context, snapshot) {
        final hours = snapshot.data ?? [];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              color: AppColors.background,
              child: Row(
                children: [
                  Text('Happy Hours',
                      style: AppTypography.h2
                          .copyWith(color: AppColors.textPrimary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showDialog(context, fs, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nové Happy Hours'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, 0, Spacing.lg, Spacing.md),
              color: AppColors.backgroundTertiary,
              child: Text(
                'Nastavte časové slevy, které se automaticky aplikují v pokladně v nastavené době.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: hours.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: Spacing.sm),
                          Text('Žádné Happy Hours',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textTertiary)),
                          const SizedBox(height: Spacing.sm),
                          ElevatedButton(
                            onPressed: () => _showDialog(context, fs, null),
                            child: const Text('Vytvořit první'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(Spacing.md),
                      itemCount: hours.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacing.sm),
                      itemBuilder: (_, i) =>
                          _hhCard(context, fs, hours[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _hhCard(
      BuildContext context, FirestoreService fs, HappyHour hh) {
    final isNow = hh.isActiveNow();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNow ? AppColors.success : AppColors.border,
          width: isNow ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hh.isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.schedule,
            color: hh.isActive ? AppColors.primary : AppColors.textTertiary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Text(hh.name,
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(width: Spacing.sm),
            if (isNow) _chip('Aktivní nyní', AppColors.success),
            if (!hh.isActive) _chip('Neaktivní', AppColors.textTertiary),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${hh.startTime.format()} – ${hh.endTime.format()}  •  ${_formatWeekdays(hh.weekdays)}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            Text(
              hh.discountType == HappyHourDiscountType.percentage
                  ? 'Sleva ${hh.discountValue.toStringAsFixed(0)} %'
                  : 'Sleva ${hh.discountValue.toStringAsFixed(0)} Kč',
              style: AppTypography.caption
                  .copyWith(color: AppColors.warning),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: hh.isActive,
              onChanged: (v) {
                final updated = HappyHour(
                  id: hh.id,
                  name: hh.name,
                  weekdays: hh.weekdays,
                  startTime: hh.startTime,
                  endTime: hh.endTime,
                  discountType: hh.discountType,
                  discountValue: hh.discountValue,
                  productIds: hh.productIds,
                  categoryIds: hh.categoryIds,
                  isActive: v,
                );
                fs.setHappyHour(updated);
              },
            ),
            IconButton(
              icon: Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
              onPressed: () => _showDialog(context, fs, hh),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: AppColors.error),
              onPressed: () => _confirmDelete(context, fs, hh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTypography.caption.copyWith(color: color)),
    );
  }

  String _formatWeekdays(List<int> days) {
    if (days.length == 7) return 'Každý den';
    return days.map((d) => _weekdayNames[d]).join(', ');
  }

  void _showDialog(
      BuildContext context, FirestoreService fs, HappyHour? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    var weekdays = List<int>.from(existing?.weekdays ?? [1, 2, 3, 4, 5]);
    var startTime = existing?.startTime ?? TimeOfDay(hour: 16, minute: 0);
    var endTime = existing?.endTime ?? TimeOfDay(hour: 18, minute: 0);
    var discountType =
        existing?.discountType ?? HappyHourDiscountType.percentage;
    final discountCtrl = TextEditingController(
        text: existing?.discountValue.toStringAsFixed(0) ?? '20');
    var isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Nové Happy Hours' : 'Upravit'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Název'),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text('Dny v týdnu',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: Spacing.xs),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final active = weekdays.contains(day);
                      return FilterChip(
                        label: Text(_weekdayNames[day]),
                        selected: active,
                        onSelected: (v) => setS(() {
                          if (v) {
                            weekdays.add(day);
                          } else {
                            weekdays.remove(day);
                          }
                          weekdays.sort();
                        }),
                      );
                    }),
                  ),
                  const SizedBox(height: Spacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: material.TimeOfDay(
                                  hour: startTime.hour,
                                  minute: startTime.minute),
                            );
                            if (t != null) {
                              setS(() => startTime =
                                  TimeOfDay(hour: t.hour, minute: t.minute));
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Od'),
                            child: Text(startTime.format()),
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: material.TimeOfDay(
                                  hour: endTime.hour,
                                  minute: endTime.minute),
                            );
                            if (t != null) {
                              setS(() => endTime =
                                  TimeOfDay(hour: t.hour, minute: t.minute));
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Do'),
                            child: Text(endTime.format()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  DropdownButtonFormField<HappyHourDiscountType>(
                    value: discountType,
                    decoration:
                        const InputDecoration(labelText: 'Typ slevy'),
                    items: HappyHourDiscountType.values
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) => setS(() => discountType = v!),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hodnota slevy',
                      suffixText: discountType ==
                              HappyHourDiscountType.percentage
                          ? '%'
                          : 'Kč',
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Aktivní',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    value: isActive,
                    onChanged: (v) => setS(() => isActive = v),
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
                final value = double.tryParse(discountCtrl.text) ?? 0;
                final hh = HappyHour(
                  id: existing?.id ?? const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  weekdays: weekdays,
                  startTime: startTime,
                  endTime: endTime,
                  discountType: discountType,
                  discountValue: value,
                  isActive: isActive,
                );
                fs.setHappyHour(hh);
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
      BuildContext context, FirestoreService fs, HappyHour hh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat Happy Hours?'),
        content: Text('Opravdu chcete smazat "${hh.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              fs.deleteHappyHour(hh.id);
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


