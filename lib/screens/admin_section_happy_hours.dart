import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:uuid/uuid.dart';
import '../models/happy_hour_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'admin_widgets.dart';

class AdminSectionHappyHours extends StatelessWidget {
  final List<ProductCategory> categories;
  final List<Product> products;

  const AdminSectionHappyHours({super.key, required this.categories, required this.products});

  static const _weekdayNames = ['', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

  String _formatWeekdays(List<int> days) {
    if (days.length == 7) return 'Každý den';
    return days.map((d) => _weekdayNames[d]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<HappyHour>>(
      stream: fs.happyHoursStream(),
      builder: (context, snapshot) {
        final hours = snapshot.data ?? [];
        return Expanded(
          child: Column(
            children: [
              Container(
                color: AT.bg,
                padding: const EdgeInsets.fromLTRB(AT.pagePad, AT.pagePad, AT.pagePad, 12),
                child: Row(
                  children: [
                    Text('Časové slevy aplikované automaticky v pokladně.', style: AT.rowSub),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showDialog(context, fs, null),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nové Happy Hours'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: hours.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.schedule_rounded,
                        title: 'Žádné Happy Hours',
                        subtitle: 'Nastavte časové slevy pro konkrétní hodiny nebo dny',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AT.pagePad),
                        itemCount: hours.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AT.cardGap),
                        itemBuilder: (_, i) => _hhCard(context, fs, hours[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hhCard(BuildContext context, FirestoreService fs, HappyHour hh) {
    final isNow = hh.isActiveNow();
    return Container(
      decoration: BoxDecoration(
        color: AT.white,
        borderRadius: BorderRadius.circular(16),
        border: isNow ? Border.all(color: AppColors.success, width: 1.5) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AT.rowPadH, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: hh.isActive ? AppColors.primary.withValues(alpha: 0.12) : AT.bgWarm,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.schedule_rounded, color: hh.isActive ? AppColors.primary : AT.ink3, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(hh.name, style: AT.cardTitle),
                      const SizedBox(width: 8),
                      if (isNow) AdminBadge(label: 'Aktivní nyní', color: AppColors.success),
                      if (!hh.isActive) AdminBadge(label: 'Neaktivní', color: AT.ink3),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${hh.startTime.format()} – ${hh.endTime.format()}  ·  ${_formatWeekdays(hh.weekdays)}',
                    style: AT.rowSub,
                  ),
                  Text(
                    hh.discountType == HappyHourDiscountType.percentage
                        ? 'Sleva ${hh.discountValue.toStringAsFixed(0)} %'
                        : 'Sleva ${hh.discountValue.toStringAsFixed(0)} Kč',
                    style: AT.rowSub.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Switch(
              value: hh.isActive,
              onChanged: (v) => fs.setHappyHour(HappyHour(
                id: hh.id, name: hh.name, weekdays: hh.weekdays,
                startTime: hh.startTime, endTime: hh.endTime,
                discountType: hh.discountType, discountValue: hh.discountValue,
                productIds: hh.productIds, categoryIds: hh.categoryIds, isActive: v,
              )),
            ),
            IconButton(icon: Icon(Icons.edit_rounded, size: 18, color: AT.ink3), onPressed: () => _showDialog(context, fs, hh)),
            IconButton(icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), onPressed: () => _confirmDelete(context, fs, hh)),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, FirestoreService fs, HappyHour? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var weekdays = List<int>.from(existing?.weekdays ?? [1, 2, 3, 4, 5]);
    var startTime = existing?.startTime ?? TimeOfDay(hour: 16, minute: 0);
    var endTime = existing?.endTime ?? TimeOfDay(hour: 18, minute: 0);
    var discountType = existing?.discountType ?? HappyHourDiscountType.percentage;
    final discountCtrl = TextEditingController(text: existing?.discountValue.toStringAsFixed(0) ?? '20');
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
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Název')),
                  const SizedBox(height: 16),
                  Text('Dny v týdnu', style: AT.sectionLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final active = weekdays.contains(day);
                      return FilterChip(
                        label: Text(_weekdayNames[day]),
                        selected: active,
                        onSelected: (v) => setS(() { if (v) weekdays.add(day); else weekdays.remove(day); weekdays.sort(); }),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: InkWell(
                        onTap: () async {
                          final t = await showTimePicker(context: ctx, initialTime: material.TimeOfDay(hour: startTime.hour, minute: startTime.minute));
                          if (t != null) setS(() => startTime = TimeOfDay(hour: t.hour, minute: t.minute));
                        },
                        child: InputDecorator(decoration: const InputDecoration(labelText: 'Od'), child: Text(startTime.format())),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: InkWell(
                        onTap: () async {
                          final t = await showTimePicker(context: ctx, initialTime: material.TimeOfDay(hour: endTime.hour, minute: endTime.minute));
                          if (t != null) setS(() => endTime = TimeOfDay(hour: t.hour, minute: t.minute));
                        },
                        child: InputDecorator(decoration: const InputDecoration(labelText: 'Do'), child: Text(endTime.format())),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<HappyHourDiscountType>(
                    value: discountType,
                    decoration: const InputDecoration(labelText: 'Typ slevy'),
                    items: HappyHourDiscountType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                    onChanged: (v) => setS(() => discountType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Hodnota slevy', suffixText: discountType == HappyHourDiscountType.percentage ? '%' : 'Kč'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('Aktivní', style: AT.rowTitle), value: isActive, onChanged: (v) => setS(() => isActive = v)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                fs.setHappyHour(HappyHour(id: existing?.id ?? const Uuid().v4(), name: nameCtrl.text.trim(), weekdays: weekdays, startTime: startTime, endTime: endTime, discountType: discountType, discountValue: double.tryParse(discountCtrl.text) ?? 0, isActive: isActive));
                Navigator.pop(ctx);
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService fs, HappyHour hh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat Happy Hours?'),
        content: Text('Opravdu chcete smazat "${hh.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
          ElevatedButton(onPressed: () { fs.deleteHappyHour(hh.id); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Smazat')),
        ],
      ),
    );
  }
}
