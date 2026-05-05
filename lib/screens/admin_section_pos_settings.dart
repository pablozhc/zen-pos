import 'package:flutter/material.dart';
import '../models/pos_settings_model.dart';
import '../services/firestore_service.dart';
import 'admin_widgets.dart';

class AdminSectionPosSettings extends StatefulWidget {
  const AdminSectionPosSettings({super.key});

  @override
  State<AdminSectionPosSettings> createState() => _AdminSectionPosSettingsState();
}

class _AdminSectionPosSettingsState extends State<AdminSectionPosSettings> {
  final _fs = FirestoreService();
  PosSettings? _settings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _fs.getPosSettings();
    if (mounted) setState(() => _settings = s);
  }

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _saving = true);
    await _fs.savePosSettings(_settings!);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nastavení uloženo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    final s = _settings!;
    return Expanded(
      child: AdminContent(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_saving)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Uložit nastavení'),
                ),
            ],
          ),
          const SizedBox(height: AT.cardGap),
          _settingsGroup('Základní', [
            _toggle('Povinně vyžadovat zadání počtu osob', 'Při otevření účtu bude obsluha vyzvána k zadání počtu hostů.', s.requirePersonCount, (v) => setState(() => _settings = s.copyWith(requirePersonCount: v))),
            _toggle('Upozorňovat na neobsloužené hosty', 'Po uplynutí nastavené doby se zobrazí upozornění.', s.warnUnattendedGuests, (v) => setState(() => _settings = s.copyWith(warnUnattendedGuests: v))),
            if (s.warnUnattendedGuests)
              Padding(
                padding: const EdgeInsets.fromLTRB(AT.rowPadH, 0, AT.rowPadH, AT.rowPadV),
                child: Row(
                  children: [
                    Text('Upozorňovat po (min):', style: AT.rowSub),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: s.unattendedGuestsMinutes.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(suffixText: 'min', isDense: true),
                        onChanged: (v) { final n = int.tryParse(v); if (n != null) setState(() => _settings = s.copyWith(unattendedGuestsMinutes: n)); },
                      ),
                    ),
                  ],
                ),
              ),
          ]),
          const SizedBox(height: AT.cardGap),
          _settingsGroup('Platby', [
            _toggle('Spropitné při platbě hotovostí', 'Při platbě hotovostí nabídne obsluha zákazníkovi zadat spropitné.', s.showTipOnCash, (v) => setState(() => _settings = s.copyWith(showTipOnCash: v))),
            _toggle('Přeskočit spropitné u karet', 'Při kartové platbě zákazník přejde přímo na terminál.', s.skipTipOnCard, (v) => setState(() => _settings = s.copyWith(skipTipOnCard: v))),
            _toggle('Zrychlená platba', 'Tlačítka přímé platby bez mezikroku.', s.quickPayment, (v) => setState(() => _settings = s.copyWith(quickPayment: v))),
          ]),
          const SizedBox(height: AT.cardGap),
          _settingsGroup('Displej', [
            _toggle('Větší ikony produktů', 'Zvětšení ikon pro zařízení 14" a větší.', s.largeIcons, (v) => setState(() => _settings = s.copyWith(largeIcons: v))),
            _toggle('Mapa stolů', 'Zjednodušený nákres stolů (pro tablety 14–15").', s.tableMap, (v) => setState(() => _settings = s.copyWith(tableMap: v))),
          ]),
          const SizedBox(height: AT.cardGap),
          _settingsGroup('Tisk', [
            _toggle('Malý formát tisku', 'Zmenšení písma snižuje spotřebu papíru o ~30 %.', s.smallPrintFormat, (v) => setState(() => _settings = s.copyWith(smallPrintFormat: v))),
            _toggle('Tisknout bez hlavičky', 'Objednávky bez standardního 2 cm záhlaví.', s.printWithoutHeader, (v) => setState(() => _settings = s.copyWith(printWithoutHeader: v))),
          ]),
        ],
      ),
    );
  }

  Widget _settingsGroup(String title, List<Widget> children) {
    return AdminCardSection(
      title: title,
      children: children.asMap().entries.map((e) => Column(
        children: [
          e.value,
          if (e.key < children.length - 1) const Divider(height: 1, thickness: 0.5, color: AT.border),
        ],
      )).toList(),
    );
  }

  Widget _toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: AT.rowTitle),
        subtitle: Text(subtitle, style: AT.rowSub),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
