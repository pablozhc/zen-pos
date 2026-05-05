import 'package:flutter/material.dart';
import '../models/pos_settings_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class AdminSectionPosSettings extends StatefulWidget {
  const AdminSectionPosSettings({super.key});

  @override
  State<AdminSectionPosSettings> createState() =>
      _AdminSectionPosSettingsState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nastavení uloženo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = _settings!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Nastavení pokladny',
                  style:
                      AppTypography.h2.copyWith(color: AppColors.textPrimary)),
              const Spacer(),
              if (_saving)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Uložit'),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          _section('Základní nastavení', [
            _toggle(
              'Povinně vyžadovat zadání počtu osob',
              'Při otevření nového účtu bude obsluha vyzvána k zadání počtu hostů.',
              s.requirePersonCount,
              (v) => setState(() => _settings = s.copyWith(requirePersonCount: v)),
            ),
            _toggle(
              'Upozorňovat na neobsloužené hosty',
              'Po uplynutí nastavené doby se zobrazí upozornění na neaktivní účet.',
              s.warnUnattendedGuests,
              (v) => setState(() => _settings = s.copyWith(warnUnattendedGuests: v)),
            ),
            if (s.warnUnattendedGuests)
              Padding(
                padding: const EdgeInsets.only(left: Spacing.lg, top: Spacing.xs),
                child: Row(
                  children: [
                    Text('Upozorňovat po (min):',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: Spacing.sm),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: s.unattendedGuestsMinutes.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            suffixText: 'min', isDense: true),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null) {
                            setState(() => _settings = s.copyWith(
                                unattendedGuestsMinutes: n));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ]),
          const SizedBox(height: Spacing.lg),
          _section('Možnosti platby', [
            _toggle(
              'Zobrazit možnost zadání spropitného při platbě hotovostí',
              'Při platbě hotovostí obsluha nabídne zákazníkovi zadat spropitné.',
              s.showTipOnCash,
              (v) => setState(() => _settings = s.copyWith(showTipOnCash: v)),
            ),
            _toggle(
              'Přeskočit zadávání spropitného při platbě kartou',
              'Při kartové platbě bude zákazník přesměrován přímo na terminál.',
              s.skipTipOnCard,
              (v) => setState(() => _settings = s.copyWith(skipTipOnCard: v)),
            ),
            _toggle(
              'Zrychlená platba',
              'V pokladně se zobrazí tlačítka přímé platby (Hotovost, Karta) bez mezikroku.',
              s.quickPayment,
              (v) => setState(() => _settings = s.copyWith(quickPayment: v)),
            ),
          ]),
          const SizedBox(height: Spacing.lg),
          _section('Doplňkové funkce', [
            _toggle(
              'Větší ikony na pokladně',
              'Zvětšení ikon produktů pro zařízení 14" a větší.',
              s.largeIcons,
              (v) => setState(() => _settings = s.copyWith(largeIcons: v)),
            ),
            _toggle(
              'Mapa stolů na pokladnách',
              'Zobrazení stolů ve zjednodušeném nákresu (pro tablety 14–15").',
              s.tableMap,
              (v) => setState(() => _settings = s.copyWith(tableMap: v)),
            ),
          ]),
          const SizedBox(height: Spacing.lg),
          _section('Tisk objednávek', [
            _toggle(
              'Použít malý formát tisku objednávky',
              'Zmenšení písma snižuje spotřebu papíru o ~30 %.',
              s.smallPrintFormat,
              (v) => setState(
                  () => _settings = s.copyWith(smallPrintFormat: v)),
            ),
            _toggle(
              'Tisknout bez hlavičky',
              'Každá vytištěná objednávka nebude mít standardní 2 cm záhlaví.',
              s.printWithoutHeader,
              (v) => setState(
                  () => _settings = s.copyWith(printWithoutHeader: v)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.md, Spacing.md, Spacing.md, 0),
            child: Text(title.toUpperCase(),
                style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
          ...children
              .expand((w) => [
                    w,
                    if (w != children.last)
                      Divider(height: 1, color: AppColors.divider),
                  ])
              .toList(),
        ],
      ),
    );
  }

  Widget _toggle(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.xs),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
