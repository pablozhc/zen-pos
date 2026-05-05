import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Zen POS Admin — shared design tokens + components
// Every admin section MUST use these. Never hardcode fonts/padding/colors.
// ─────────────────────────────────────────────────────────────────────────────

class AT {
  // Colors
  static const Color bg       = Color(0xFFFAF8F5);
  static const Color bgWarm   = Color(0xFFF3F0EB);
  static const Color border   = Color(0xFFEDE9E3);
  static const Color ink1     = Color(0xFF1A0F0A);
  static const Color ink2     = Color(0xFF5A4A3A);
  static const Color ink3     = Color(0xFF9A8F85);
  static const Color white    = Color(0xFFFFFFFF);
  static const Color indigo   = Color(0xFF5856D6);

  // Text styles
  static const TextStyle pageTitle     = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink1, letterSpacing: -0.3, height: 1.2);
  static const TextStyle pageSub       = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: ink3);
  static const TextStyle cardTitle     = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink1, letterSpacing: -0.1);
  static const TextStyle sectionLabel  = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink3, letterSpacing: 0.06);
  static const TextStyle rowTitle      = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ink1);
  static const TextStyle rowSub        = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: ink3);
  static const TextStyle rowValue      = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink1);
  static const TextStyle mono          = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink1, fontFeatures: [FontFeature.tabularFigures()]);
  static const TextStyle badge         = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.02);

  // Card decoration
  static BoxDecoration get card => BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x08000000), blurRadius: 1),
    ],
  );

  // Spacing
  static const double pagePad  = 24.0;
  static const double cardGap  = 16.0;
  static const double rowPadH  = 16.0;
  static const double rowPadV  = 12.0;
}

// ── Wraps section content in standard scroll + padding ───────────────────────
class AdminContent extends StatelessWidget {
  final List<Widget> children;
  const AdminContent({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AT.pagePad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ── Standard floating card ────────────────────────────────────────────────────
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: AT.card,
      child: child,
    );
  }
}

// ── Card with header row (title + optional trailing) ─────────────────────────
class AdminCardSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const AdminCardSection({super.key, required this.title, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AT.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Text(title, style: AT.cardTitle),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AT.border),
          ...children,
        ],
      ),
    );
  }
}

// ── Standard list row ─────────────────────────────────────────────────────────
class AdminListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const AdminListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AT.rowPadH, vertical: AT.rowPadV),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AT.rowTitle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AT.rowSub),
                      ],
                    ],
                  ),
                ),
                if (value != null) Text(value!, style: AT.rowValue),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, color: AT.border, indent: AT.rowPadH),
      ],
    );
  }
}

// ── Section label (UPPERCASE small) ──────────────────────────────────────────
class AdminSectionLabel extends StatelessWidget {
  final String text;
  const AdminSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(text.toUpperCase(), style: AT.sectionLabel),
    );
  }
}

// ── KPI card (240px, left accent bar) ────────────────────────────────────────
class AdminKpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;

  const AdminKpiCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: AT.card,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1, color: AT.ink1)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(icon, color: accentColor, size: 12),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(label, style: AT.rowSub.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── KPI grid (Wrap of AdminKpiCard) ──────────────────────────────────────────
class AdminKpiGrid extends StatelessWidget {
  final List<AdminKpiCard> cards;
  const AdminKpiGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: AT.cardGap, runSpacing: AT.cardGap, children: cards);
  }
}

// ── Status badge / pill ───────────────────────────────────────────────────────
class AdminBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AdminBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AT.badge.copyWith(color: color)),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AdminEmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AT.bgWarm, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: AT.ink3, size: 26),
            ),
            const SizedBox(height: 14),
            Text(title, style: AT.cardTitle.copyWith(fontSize: 15)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: AT.rowSub),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Action button row (bottom of dialogs/forms) ───────────────────────────────
class AdminActionRow extends StatelessWidget {
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool destructive;

  const AdminActionRow({
    super.key,
    this.cancelLabel = 'Zrušit',
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: onCancel, child: Text(cancelLabel)),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onConfirm,
          style: destructive
              ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
