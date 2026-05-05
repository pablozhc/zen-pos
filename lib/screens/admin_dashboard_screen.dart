import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../viewmodels/products_viewmodel.dart';
import '../viewmodels/tables_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/product_model.dart';
import '../models/payment_model.dart';
import '../models/staff_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';
import '../services/printer_service.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'admin_login_screen.dart';
import 'admin_section_profit.dart';
import 'admin_section_receipts.dart';
import 'admin_section_cash.dart';
import 'admin_section_storno.dart';
import 'admin_section_addons.dart';
import 'admin_section_happy_hours.dart';
import 'admin_section_tables_manage.dart';
import 'admin_section_pos_settings.dart';
import 'admin_section_stock.dart';

enum AdminGroup { reports, accounts, menu, team, settings }

enum AdminSection {
  revenue, overview, history,
  profit, receipts, cash, storno,
  products, categories, addons, happyHours,
  staff, roles,
  tablesManage, posSettings,
  stock,
  printer,
}

enum RevenuePeriod { day, week, month }

// Sub-tabs per group
const _groupSections = {
  AdminGroup.reports:   [AdminSection.revenue, AdminSection.profit, AdminSection.overview, AdminSection.history, AdminSection.storno],
  AdminGroup.accounts:  [AdminSection.receipts, AdminSection.cash],
  AdminGroup.menu:      [AdminSection.products, AdminSection.categories, AdminSection.addons, AdminSection.happyHours],
  AdminGroup.team:      [AdminSection.staff, AdminSection.roles],
  AdminGroup.settings:  [AdminSection.tablesManage, AdminSection.posSettings, AdminSection.stock, AdminSection.printer],
};

const _groupLabels = {
  AdminGroup.reports:  'Přehledy',
  AdminGroup.accounts: 'Účty',
  AdminGroup.menu:     'Menu',
  AdminGroup.team:     'Tým',
  AdminGroup.settings: 'Nastavení',
};

const _sectionLabels = {
  AdminSection.revenue:     'Tržby',
  AdminSection.profit:      'Zisk',
  AdminSection.overview:    'Přehled',
  AdminSection.history:     'Historie',
  AdminSection.storno:      'Storna',
  AdminSection.receipts:    'Účtenky',
  AdminSection.cash:        'Pokladna',
  AdminSection.products:    'Produkty',
  AdminSection.categories:  'Kategorie',
  AdminSection.addons:      'Přídavky',
  AdminSection.happyHours:  'Happy Hours',
  AdminSection.staff:       'Personál',
  AdminSection.roles:       'Role',
  AdminSection.tablesManage:'Stoly',
  AdminSection.posSettings: 'POS',
  AdminSection.stock:       'Sklad',
  AdminSection.printer:     'Tiskárna',
};

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminGroup _currentGroup = AdminGroup.reports;
  AdminSection _currentSection = AdminSection.revenue;
  RevenuePeriod _selectedPeriod = RevenuePeriod.day;
  String? _selectedCategoryId;

  // ── Design tokens ──
  static const Color _bg        = Color(0xFFFAF8F5);
  static const Color _bgWarm    = Color(0xFFF3F0EB);
  static const Color _border    = Color(0xFFEDE9E3);
  static const Color _ink1      = Color(0xFF1A0F0A);
  static const Color _ink2      = Color(0xFF5A4A3A);
  static const Color _ink3      = Color(0xFF9A8F85);
  static const Color _white     = Color(0xFFFFFFFF);
  static const Color _indigo    = Color(0xFF5856D6);

  void _selectGroup(AdminGroup group) {
    final sections = _groupSections[group]!;
    setState(() {
      _currentGroup = group;
      _currentSection = sections.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeViewModel>();
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopNav(),
          _buildSubTabs(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ── TOP NAV ──────────────────────────────────────────────────
  Widget _buildTopNav() {
    final auth = context.read<AuthViewModel>();
    return Container(
      height: 52,
      color: _white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 1, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: _indigo, borderRadius: BorderRadius.circular(7)),
            child: const Center(child: Text('Z', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
          ),
          const SizedBox(width: 6),
          const Text('Zen POS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink1, letterSpacing: -0.2)),
          const SizedBox(width: 28),
          // Group tabs
          ...AdminGroup.values.map((g) => _buildTopTab(g)),
          const Spacer(),
          // User avatar
          GestureDetector(
            onTap: () {
              context.read<AuthViewModel>().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
              );
            },
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: _indigo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(15)),
              child: Center(
                child: Text(
                  (auth.currentUser?.name.isNotEmpty == true) ? auth.currentUser!.name[0].toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _indigo),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTab(AdminGroup group) {
    final isActive = _currentGroup == group;
    return GestureDetector(
      onTap: () => _selectGroup(group),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _groupLabels[group]!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? _white : _ink3,
          ),
        ),
      ),
    );
  }

  // ── SUB-TABS ─────────────────────────────────────────────────
  Widget _buildSubTabs() {
    final sections = _groupSections[_currentGroup]!;
    return Container(
      height: 42,
      color: _bgWarm,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: sections.map((s) => _buildSubTab(s)).toList(),
      ),
    );
  }

  Widget _buildSubTab(AdminSection section) {
    final isActive = _currentSection == section;
    return GestureDetector(
      onTap: () => setState(() => _currentSection = section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(right: 4, top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? _white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 1))]
              : [],
        ),
        child: Text(
          _sectionLabels[section]!,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? _indigo : _ink3,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final tablesVM = context.watch<TablesViewModel>();
    final productsVM = context.watch<ProductsViewModel>();
    final payments = _getFilteredPayments(tablesVM);
    final range = _getDateRange();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final periodLabel = ['Den', 'Týden', 'Měsíc'][_selectedPeriod.index];
    final dateRangeLabel =
        '${dateFormat.format(range.start)} – ${dateFormat.format(range.end)}';

    switch (_currentSection) {
      case AdminSection.revenue:
        return _buildRevenueContent();
      case AdminSection.profit:
        return AdminSectionProfit(
          payments: payments,
          periodLabel: periodLabel,
          dateRangeLabel: dateRangeLabel,
        );
      case AdminSection.overview:
        return _buildOverviewContent();
      case AdminSection.history:
        return _buildHistoryContent();
      case AdminSection.storno:
        return AdminSectionStorno(
          payments: tablesVM.paymentHistory,
          periodLabel: periodLabel,
        );
      case AdminSection.receipts:
        return AdminSectionReceipts(
          payments: tablesVM.paymentHistory,
        );
      case AdminSection.cash:
        return AdminSectionCash(
          payments: tablesVM.paymentHistory,
        );
      case AdminSection.products:
        return _buildProductsContent();
      case AdminSection.categories:
        return _buildCategoriesContent();
      case AdminSection.addons:
        return AdminSectionAddons(
          categories: productsVM.categories,
          products: productsVM.products,
        );
      case AdminSection.happyHours:
        return AdminSectionHappyHours(
          categories: productsVM.categories,
          products: productsVM.products,
        );
      case AdminSection.staff:
        return _buildStaffContent();
      case AdminSection.roles:
        return _buildRolesContent();
      case AdminSection.tablesManage:
        return AdminSectionTablesManage(tables: tablesVM.tables);
      case AdminSection.posSettings:
        return const AdminSectionPosSettings();
      case AdminSection.stock:
        return const AdminSectionStock();
      case AdminSection.printer:
        return _buildPrinterContent();
    }
  }

  // ==================== HELPERS ====================

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedPeriod) {
      case RevenuePeriod.day:
        return DateTimeRange(start: today, end: now);
      case RevenuePeriod.week:
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: now);
      case RevenuePeriod.month:
        return DateTimeRange(start: today.subtract(const Duration(days: 29)), end: now);
    }
  }

  List<Payment> _getFilteredPayments(TablesViewModel tablesVM) {
    final range = _getDateRange();
    return tablesVM.paymentHistory.where((p) {
      return !p.timestamp.isBefore(range.start) && !p.timestamp.isAfter(range.end);
    }).toList();
  }

  // ==================== TRŽBY (REVENUE) ====================

  Widget _buildPageHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 20, 0),
      height: 56,
      color: _bg,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink1, letterSpacing: -0.3)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(fontSize: 11, color: _ink3, fontWeight: FontWeight.w400)),
            ],
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildRevenueContent() {
    final tablesVM = context.watch<TablesViewModel>();
    final payments = _getFilteredPayments(tablesVM);
    final range = _getDateRange();

    final totalRevenue = payments.fold(0.0, (sum, p) => sum + p.totalWithTip);
    final avgPerPayment = payments.isNotEmpty ? totalRevenue / payments.length : 0.0;
    final paymentCount = payments.length;

    final dateFormat = DateFormat('dd.MM.yyyy');
    final subtitle = '${dateFormat.format(range.start)} – ${dateFormat.format(range.end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(title: 'Tržby', subtitle: subtitle, trailing: _buildPeriodFilter()),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 KPI cards
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildRevenueStatCard(
                        Icons.receipt_long_rounded,
                        'Příjmy s DPH',
                        CurrencyFormatter.format(totalRevenue),
                        AppColors.primary,
                      ),
                    _buildRevenueStatCard(
                        Icons.person_rounded,
                        'Průměrná útrata',
                        CurrencyFormatter.format(avgPerPayment),
                        AppColors.info,
                      ),
                    _buildRevenueStatCard(
                        Icons.groups_rounded,
                        'Počet plateb',
                        '$paymentCount',
                        AppColors.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildRevenueChart(payments),
                const SizedBox(height: 24),
                _buildPaymentBreakdownTable(payments),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('Den', RevenuePeriod.day),
          _buildPeriodButton('Týden', RevenuePeriod.week),
          _buildPeriodButton('Měsíc', RevenuePeriod.month),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, RevenuePeriod period) {
    final isActive = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueStatCard(IconData icon, String label, String value, Color accentColor) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 1, offset: const Offset(0, 0)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(color: _ink1, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(icon, color: accentColor, size: 12),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(label, style: const TextStyle(color: _ink3, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
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

  Widget _buildRevenueChart(List<Payment> payments) {
    final Map<String, double> dailyRevenue = {};
    final dateFormat = DateFormat('dd.MM.');
    final range = _getDateRange();

    int dayCount;
    switch (_selectedPeriod) {
      case RevenuePeriod.day:
        dayCount = 1;
      case RevenuePeriod.week:
        dayCount = 7;
      case RevenuePeriod.month:
        dayCount = 30;
    }

    for (int i = 0; i < dayCount; i++) {
      final day = range.start.add(Duration(days: i));
      dailyRevenue[dateFormat.format(day)] = 0;
    }

    for (final payment in payments) {
      final key = dateFormat.format(payment.timestamp);
      dailyRevenue[key] = (dailyRevenue[key] ?? 0) + payment.totalWithTip;
    }

    final entries = dailyRevenue.entries.toList();
    final maxY = entries.isEmpty
        ? 100.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY == 0 ? 100.0 : maxY * 1.2;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Přehled tržeb', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            height: 220,
            child: entries.length <= 1
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entries.isNotEmpty ? CurrencyFormatter.format(entries.first.value) : '0 Kč',
                          style: AppTypography.h2.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text('Celkové tržby dnes', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMaxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            interval: chartMaxY / 4,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  CurrencyFormatter.format(value),
                                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary, fontSize: 10),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _selectedPeriod == RevenuePeriod.month ? 5 : 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= entries.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  entries[idx].key,
                                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (entries.length - 1).toDouble().clamp(0, double.infinity),
                      minY: 0,
                      maxY: chartMaxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: entries.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.value);
                          }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.2,
                          color: AppColors.primary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: entries.length <= 14,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppColors.primary,
                                strokeWidth: 2,
                                strokeColor: AppColors.cardBackground,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.backgroundTertiary,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.x.toInt();
                              final label = idx >= 0 && idx < entries.length ? entries[idx].key : '';
                              return LineTooltipItem(
                                '$label\n${CurrencyFormatter.format(spot.y)}',
                                AppTypography.caption.copyWith(color: AppColors.textPrimary),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownTable(List<Payment> payments) {
    final cardPayments = payments.where((p) => p.method == PaymentMethod.card).toList();
    final cashPayments = payments.where((p) => p.method == PaymentMethod.cash).toList();

    final cardTotal = cardPayments.fold(0.0, (sum, p) => sum + p.totalWithTip);
    final cashTotal = cashPayments.fold(0.0, (sum, p) => sum + p.totalWithTip);
    final cardAvg = cardPayments.isNotEmpty ? cardTotal / cardPayments.length : 0.0;
    final cashAvg = cashPayments.isNotEmpty ? cashTotal / cashPayments.length : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text('Tržby dle typu plateb', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
          ),
          Divider(color: AppColors.divider, height: 1),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Typ platby', style: AppTypography.caption.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Příjmy', style: AppTypography.caption.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Průměrná útrata na hlavu', style: AppTypography.caption.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Počet osob', style: AppTypography.caption.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider, height: 1),
          if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.sentiment_dissatisfied, color: AppColors.textTertiary, size: 32),
                    const SizedBox(height: Spacing.sm),
                    Text('Žádné položky nenalezeny', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            )
          else ...[
            if (cardPayments.isNotEmpty)
              _buildBreakdownRow(Icons.credit_card, 'Karta', cardTotal, cardAvg, cardPayments.length),
            if (cashPayments.isNotEmpty)
              _buildBreakdownRow(Icons.payments, 'Hotovost', cashTotal, cashAvg, cashPayments.length),
            Divider(color: AppColors.divider, height: 1),
            // Total row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Celkem', style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      CurrencyFormatter.format(cardTotal + cashTotal),
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CurrencyFormatter.format(payments.isNotEmpty ? (cardTotal + cashTotal) / payments.length : 0),
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${payments.length}',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spacing.xs),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(IconData icon, String label, double total, double avg, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: Spacing.xs),
                Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(CurrencyFormatter.format(total), style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text(CurrencyFormatter.format(avg), style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text('$count', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ==================== AKTUÁLNÍ PŘEHLED (OVERVIEW) ====================

  Widget _buildOverviewContent() {
    final tablesVM = context.watch<TablesViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(title: 'Aktuální přehled'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildRevenueStatCard(Icons.table_bar_rounded, 'Aktivní stoly', '${tablesVM.activeTables.length}', AppColors.primary),
              _buildRevenueStatCard(Icons.receipt_long_rounded, 'Otevřené tržby', CurrencyFormatter.format(tablesVM.openTabsTotal), AppColors.warning),
              _buildRevenueStatCard(Icons.check_circle_rounded, 'Volné stoly', '${tablesVM.freeTables.length}', AppColors.success),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          Text('Aktivní stoly', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: Spacing.md),
          if (tablesVM.activeTables.isEmpty)
            Container(
              padding: const EdgeInsets.all(Spacing.xl),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: Text('Žádné aktivní stoly', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
              ),
            )
          else
            ...tablesVM.activeTables.map((table) => Container(
              margin: const EdgeInsets.only(bottom: Spacing.sm),
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${table.number}', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stůl ${table.number}', style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
                        Text(
                          '${table.currentOrder?.items.length ?? 0} položek',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(table.displayAmount),
                    style: AppTypography.monoLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== CATEGORIES ====================

  Widget _buildCategoriesContent() {
    final productsVM = context.watch<ProductsViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          title: 'Kategorie',
          trailing: ElevatedButton.icon(
            onPressed: () => _showAddCategoryDialog(productsVM),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Přidat kategorii'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: productsVM.categories.map((cat) => Container(
                margin: const EdgeInsets.only(bottom: Spacing.sm),
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.title, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                          Text(
                            '${productsVM.getProductsByCategory(cat.id).length} produktů',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'ID: ${cat.id}',
                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(width: Spacing.md),
                    IconButton(
                      onPressed: () => _showDeleteCategoryDialog(productsVM, cat),
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    ),
                  ],
                ),
              )).toList(),
          ),
        ),
      ],
    );
  }

  // ==================== PRODUCTS ====================

  Widget _buildProductsContent() {
    final productsVM = context.watch<ProductsViewModel>();
    final categories = productsVM.categories;

    // Auto-select first category if none selected or selected was deleted
    if (categories.isNotEmpty &&
        (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId))) {
      _selectedCategoryId = categories.first.id;
    }

    final selectedCat = categories.isEmpty
        ? null
        : categories.firstWhere(
            (c) => c.id == _selectedCategoryId,
            orElse: () => categories.first,
          );
    final products = selectedCat != null ? productsVM.getProductsByCategory(selectedCat.id) : <Product>[];

    // Category tabs above product list
    final categoryTabs = categories.isEmpty
        ? const SizedBox.shrink()
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: categories.map((cat) {
                final isSelected = cat.id == _selectedCategoryId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${cat.emoji}  ${cat.title}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          title: 'Produkty',
          trailing: ElevatedButton.icon(
            onPressed: () => _showProductFormDialog(productsVM),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Přidat produkt'),
          ),
        ),
        categoryTabs,
        const SizedBox(height: 8),
        // Products list for selected category
        Expanded(
            child: products.isEmpty
                ? Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Spacing.xxl),
                      child: Text(
                        categories.isEmpty ? 'Nejprve vytvořte kategorii' : 'Žádné produkty v této kategorii',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  )
                : ListView(
                    children: products.map((product) => InkWell(
                      onTap: () => _showProductFormDialog(productsVM, existingProduct: product),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: Spacing.xs),
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
                        ),
                        child: Row(
                          children: [
                            Text(product.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                                  if (product.description.isNotEmpty)
                                    Text(
                                      product.description,
                                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xxs),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundTertiary,
                                borderRadius: BorderRadius.circular(CornerRadius.sm),
                              ),
                              child: Text(
                                CurrencyFormatter.format(product.price),
                                style: AppTypography.monoMedium.copyWith(color: AppColors.primary),
                              ),
                            ),
                            if (!product.isAvailable)
                              Padding(
                                padding: const EdgeInsets.only(left: Spacing.xs),
                                child: Icon(Icons.visibility_off, color: AppColors.textTertiary, size: 18),
                              ),
                            const SizedBox(width: Spacing.sm),
                            Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                            const SizedBox(width: Spacing.xs),
                            IconButton(
                              onPressed: () => productsVM.deleteProduct(product.id),
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
        ),
      ],
    );
  }

  // ==================== HISTORY ====================

  Widget _buildHistoryContent() {
    final tablesVM = context.watch<TablesViewModel>();
    final payments = tablesVM.paymentHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(title: 'Historie plateb'),
        Expanded(
          child: payments.isEmpty
              ? const Center(child: Text('Žádné platby'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: payments.reversed.map((payment) => Container(
                      margin: const EdgeInsets.only(bottom: Spacing.sm),
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            payment.method == PaymentMethod.card ? Icons.credit_card : Icons.payments,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stůl ${payment.tableNumber}',
                                  style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                                ),
                                Text(
                                  '${payment.timestamp.hour}:${payment.timestamp.minute.toString().padLeft(2, '0')} - ${payment.method.title}',
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(payment.amount),
                                style: AppTypography.monoLarge.copyWith(color: AppColors.textPrimary),
                              ),
                              if (payment.tip > 0)
                                Text(
                                  '+ ${CurrencyFormatter.format(payment.tip)} tip',
                                  style: AppTypography.caption.copyWith(color: AppColors.success),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )).toList(),
                ),
        ),
      ],
    );
  }

  // ==================== STAFF ====================

  Widget _buildStaffContent() {
    final auth = context.watch<AuthViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          title: 'Personál',
          trailing: ElevatedButton.icon(
            onPressed: () => _showAddStaffDialog(auth),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Přidat člena'),
          ),
        ),
        Expanded(
          child: auth.staff.isEmpty
              ? const Center(child: Text('Žádný personál'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: auth.staff.map((member) {
                      final role = auth.getRoleById(member.roleId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: Spacing.sm),
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: member.isActive
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.backgroundTertiary,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Center(
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: member.isActive ? AppColors.primary : AppColors.textTertiary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(member.name, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                                      if (!member.isActive)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Text('(neaktivní)', style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    role?.name ?? 'Bez role',
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (member.hasAdminAccess)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Admin', style: AppTypography.caption.copyWith(color: AppColors.info)),
                              ),
                            const SizedBox(width: Spacing.sm),
                            IconButton(
                              onPressed: () => _showEditStaffDialog(auth, member),
                              icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                            ),
                            IconButton(
                              onPressed: () => _showDeleteStaffDialog(auth, member),
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ),
        ),
      ],
    );
  }

  // ==================== ROLES ====================

  Widget _buildRolesContent() {
    final auth = context.watch<AuthViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          title: 'Role',
          trailing: ElevatedButton.icon(
            onPressed: () => _showAddRoleDialog(auth),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Přidat roli'),
          ),
        ),
        Expanded(
          child: auth.roles.isEmpty
              ? const Center(child: Text('Žádné role'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: auth.roles.map((role) {
                      final memberCount = auth.staff.where((s) => s.roleId == role.id).length;
                      return Container(
                        margin: const EdgeInsets.only(bottom: Spacing.sm),
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.security, color: role.isDefault ? AppColors.primary : AppColors.textSecondary, size: 24),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(role.name, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                                          if (role.isDefault)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text('Výchozí', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        '$memberCount členů',
                                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showEditRoleDialog(auth, role),
                                  icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                ),
                                if (!role.isDefault)
                                  IconButton(
                                    onPressed: memberCount == 0
                                        ? () {
                                            auth.deleteRole(role.id);
                                          }
                                        : null,
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: memberCount == 0 ? AppColors.error : AppColors.textTertiary,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: Spacing.sm),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: role.permissions.map((perm) {
                                final label = StaffRole.allPermissions[perm] ?? perm;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundTertiary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ),
        ),
      ],
    );
  }

  // ==================== PRINTER ====================

  Widget _buildPrinterContent() {
    final printer = context.watch<PrinterService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(title: 'Tiskárna'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

          // Connection status card
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: printer.isConnected ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.isConnected ? 'Připojeno' : 'Nepřipojeno',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                      ),
                      if (printer.connectedDevice != null)
                        Text(
                          printer.connectedDevice!.name ?? printer.connectedDevice!.address ?? '',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (printer.isConnected) ...[
                  ElevatedButton(
                    onPressed: () => printer.printTestReceipt(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                    ),
                    child: const Text('Testovací tisk'),
                  ),
                  const SizedBox(width: Spacing.sm),
                  ElevatedButton(
                    onPressed: () => printer.disconnect(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('Odpojit'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Search button
          if (!printer.isConnected)
            ElevatedButton.icon(
              onPressed: () => _showPrinterSearchDialog(printer),
              icon: const Icon(Icons.bluetooth_searching, size: 20),
              label: const Text('Vyhledat tiskárny'),
            ),

          if (!printer.isConnected) ...[
            const SizedBox(height: Spacing.xl),
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jak připojit tiskárnu', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: Spacing.md),
                  _buildInstructionStep('1', 'Zapněte tiskárnu Xprinter XP-C260H'),
                  _buildInstructionStep('2', 'V nastavení tabletu spárujte tiskárnu přes Bluetooth'),
                  _buildInstructionStep('3', 'Klikněte na "Vyhledat tiskárny" výše'),
                  _buildInstructionStep('4', 'Vyberte tiskárnu ze seznamu'),
                ],
              ),
            ),
          ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(number, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showPrinterSearchDialog(PrinterService printer) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Hledám tiskárny...', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: const SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ),
    );

    final devices = await printer.getPairedDevices();

    if (!mounted) return;
    Navigator.pop(context);

    if (devices.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Žádné zařízení', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          content: Text(
            'Nejprve spárujte tiskárnu v nastavení Bluetooth vašeho tabletu.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Spárovaná zařízení', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: devices.map((device) => InkWell(
              onTap: () async {
                Navigator.pop(dialogContext);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.cardBackground,
                    title: Text('Připojuji...', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
                    content: SizedBox(
                      height: 60,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: Spacing.sm),
                            Text(device.name ?? device.address ?? '', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                final success = await printer.connect(device);

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Tiskárna připojena!'
                        : 'Připojení selhalo. Zkontrolujte, zda je tiskárna zapnutá.'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: Spacing.xs),
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(CornerRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth, color: AppColors.info, size: 24),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name ?? 'Neznámé zařízení',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                          ),
                          Text(
                            device.address ?? '',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // ==================== STAFF/ROLES DIALOGS ====================

  void _showAddStaffDialog(AuthViewModel auth) {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedRoleId = auth.roles.isNotEmpty ? auth.roles.first.id : null;
    bool addAdminAccess = false;
    String? adminError;
    bool isRegistering = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Nový člen', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Jméno'),
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'PIN (4 číslice)', counterText: ''),
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRoleId,
                    isExpanded: true,
                    dropdownColor: AppColors.cardBackground,
                    underline: const SizedBox(),
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                    items: auth.roles.map((role) => DropdownMenuItem(
                      value: role.id,
                      child: Text(role.name),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedRoleId = value);
                    },
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Row(
                  children: [
                    Text('Admin přístup', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                    const Spacer(),
                    Switch(
                      value: addAdminAccess,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setDialogState(() => addAdminAccess = v),
                    ),
                  ],
                ),
                if (addAdminAccess) ...[
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: 'E-mail'),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Na e-mail bude odeslán odkaz pro nastavení hesla',
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
                if (adminError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: Text(adminError!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: isRegistering ? null : () async {
                if (nameController.text.isEmpty ||
                    pinController.text.length != 4 ||
                    selectedRoleId == null) return;

                if (addAdminAccess && emailController.text.trim().isEmpty) {
                  setDialogState(() => adminError = 'Vyplňte e-mail');
                  return;
                }

                // Create staff member first
                auth.addStaffMember(
                  name: nameController.text,
                  pin: pinController.text,
                  roleId: selectedRoleId!,
                );

                // If admin access requested, register Firebase Auth account
                if (addAdminAccess) {
                  setDialogState(() {
                    isRegistering = true;
                    adminError = null;
                  });

                  final newMember = auth.staff.lastWhere(
                    (s) => s.name == nameController.text,
                  );
                  final error = await auth.registerAdmin(
                    email: emailController.text.trim(),
                    staffId: newMember.id,
                  );

                  if (error != null) {
                    setDialogState(() {
                      isRegistering = false;
                      adminError = error;
                    });
                    return;
                  }
                }

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (addAdminAccess && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pozvánka odeslána na ${emailController.text.trim()}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: isRegistering
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text('Přidat', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStaffDialog(AuthViewModel auth, StaffMember member) {
    final nameController = TextEditingController(text: member.name);
    final pinController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedRoleId = member.roleId;
    bool isActive = member.isActive;
    bool addAdminAccess = false;
    String? adminError;
    bool isRegistering = false;
    bool hasAdmin = member.firebaseUid != null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Upravit člena', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Jméno'),
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Nový PIN (prázdné = beze změny)', counterText: ''),
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRoleId,
                    isExpanded: true,
                    dropdownColor: AppColors.cardBackground,
                    underline: const SizedBox(),
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                    items: auth.roles.map((role) => DropdownMenuItem(
                      value: role.id,
                      child: Text(role.name),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedRoleId = value);
                    },
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Text('Aktivní', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                // Admin access section
                if (hasAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, color: AppColors.success, size: 20),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admin přístup', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                              Text(member.username ?? '', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            auth.unlinkAdmin(member.id);
                            setDialogState(() => hasAdmin = false);
                          },
                          child: Text('Odpojit', style: TextStyle(color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Text('Přidat admin přístup', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                      const Spacer(),
                      Switch(
                        value: addAdminAccess,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setDialogState(() => addAdminAccess = v),
                      ),
                    ],
                  ),
                  if (addAdminAccess) ...[
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: 'E-mail'),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Na e-mail bude odeslán odkaz pro nastavení hesla',
                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ],
                if (adminError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: Text(adminError!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: isRegistering ? null : () async {
                // Save basic staff fields
                auth.updateStaffMember(
                  member.id,
                  name: nameController.text,
                  pin: pinController.text.length == 4 ? pinController.text : null,
                  roleId: selectedRoleId,
                  isActive: isActive,
                );

                // If adding admin access, register Firebase Auth account
                if (addAdminAccess && !hasAdmin) {
                  if (emailController.text.trim().isEmpty) {
                    setDialogState(() => adminError = 'Vyplňte e-mail');
                    return;
                  }

                  setDialogState(() {
                    isRegistering = true;
                    adminError = null;
                  });

                  final error = await auth.registerAdmin(
                    email: emailController.text.trim(),
                    staffId: member.id,
                  );

                  if (error != null) {
                    setDialogState(() {
                      isRegistering = false;
                      adminError = error;
                    });
                    return;
                  }
                }

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (addAdminAccess && !hasAdmin && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pozvánka odeslána na ${emailController.text.trim()}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: isRegistering
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text('Uložit', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteStaffDialog(AuthViewModel auth, StaffMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Smazat člena?', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Člen "${member.name}" bude odstraněn.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              auth.deleteStaffMember(member.id);
              Navigator.pop(context);
            },
            child: Text('Smazat', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddRoleDialog(AuthViewModel auth) {
    final nameController = TextEditingController();
    List<String> selectedPermissions = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Nová role', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Název role'),
                ),
                const SizedBox(height: Spacing.lg),
                Text('Oprávnění', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: Spacing.sm),
                ...StaffRole.allPermissions.entries.map((entry) {
                  return CheckboxListTile(
                    value: selectedPermissions.contains(entry.key),
                    title: Text(entry.value, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedPermissions.add(entry.key);
                        } else {
                          selectedPermissions.remove(entry.key);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedPermissions.isNotEmpty) {
                  auth.addRole(name: nameController.text, permissions: selectedPermissions);
                  Navigator.pop(context);
                }
              },
              child: Text('Přidat', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoleDialog(AuthViewModel auth, StaffRole role) {
    final nameController = TextEditingController(text: role.name);
    List<String> selectedPermissions = List.from(role.permissions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Upravit roli', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Název role'),
                  enabled: !role.isDefault,
                ),
                const SizedBox(height: Spacing.lg),
                Text('Oprávnění', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: Spacing.sm),
                ...StaffRole.allPermissions.entries.map((entry) {
                  return CheckboxListTile(
                    value: selectedPermissions.contains(entry.key),
                    title: Text(entry.value, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedPermissions.add(entry.key);
                        } else {
                          selectedPermissions.remove(entry.key);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                auth.updateRole(
                  role.id,
                  name: role.isDefault ? null : nameController.text,
                  permissions: selectedPermissions,
                );
                Navigator.pop(context);
              },
              child: Text('Uložit', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CATEGORY/PRODUCT DIALOGS ====================

  void _showAddCategoryDialog(ProductsViewModel vm) {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Nová kategorie', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Název kategorie'),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: emojiController,
              style: const TextStyle(fontSize: 28),
              decoration: const InputDecoration(hintText: 'Emoji'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                vm.addCategory(
                  title: nameController.text,
                  emoji: emojiController.text.isEmpty ? '📁' : emojiController.text,
                );
                Navigator.pop(context);
              }
            },
            child: Text('Přidat', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(ProductsViewModel vm, ProductCategory cat) {
    final productCount = vm.getProductsByCategory(cat.id).length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Smazat kategorii?', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Kategorie "${cat.title}" a jejích $productCount produktů bude smazáno.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              vm.deleteCategory(cat.id);
              Navigator.pop(context);
            },
            child: Text('Smazat', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showProductFormDialog(ProductsViewModel vm, {Product? existingProduct}) {
    final isEditing = existingProduct != null;
    final nameController = TextEditingController(text: existingProduct?.name ?? '');
    final descController = TextEditingController(text: existingProduct?.description ?? '');
    final priceController = TextEditingController(
      text: existingProduct != null ? existingProduct.price.toStringAsFixed(0) : '',
    );
    final emojiController = TextEditingController(text: existingProduct?.emoji ?? '');
    String? selectedCategoryId = existingProduct?.categoryId ??
        (vm.categories.isNotEmpty ? vm.categories.first.id : null);
    bool isAvailable = existingProduct?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 640,
            padding: const EdgeInsets.all(Spacing.lg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        isEditing ? 'Upravit produkt' : 'Nový produkt',
                        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Two-column layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Název produktu', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: Spacing.xxs),
                            TextField(
                              controller: nameController,
                              style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                              decoration: const InputDecoration(hintText: 'např. French Martini'),
                              autofocus: !isEditing,
                            ),
                            const SizedBox(height: Spacing.md),
                            Text('Popis produktu', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: Spacing.xxs),
                            TextField(
                              controller: descController,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                              decoration: const InputDecoration(hintText: 'Volitelný popis...'),
                              maxLines: 3,
                              minLines: 2,
                            ),
                            const SizedBox(height: Spacing.md),
                            Text('Kategorie', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: Spacing.xxs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundTertiary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: selectedCategoryId,
                                isExpanded: true,
                                dropdownColor: AppColors.cardBackground,
                                underline: const SizedBox(),
                                style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                                items: vm.categories.map((cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text('${cat.emoji}  ${cat.title}'),
                                )).toList(),
                                onChanged: (value) {
                                  setDialogState(() => selectedCategoryId = value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacing.lg),
                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cena položky', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: Spacing.xxs),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: '0',
                                suffixText: 'Kč',
                                suffixStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            Text('Emoji', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: Spacing.xxs),
                            TextField(
                              controller: emojiController,
                              style: const TextStyle(fontSize: 28),
                              decoration: const InputDecoration(hintText: '📦'),
                            ),
                            const SizedBox(height: Spacing.lg),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundTertiary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isAvailable ? Icons.visibility : Icons.visibility_off,
                                    color: isAvailable ? AppColors.success : AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Dostupný v tabletu',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                    ),
                                  ),
                                  Switch(
                                    value: isAvailable,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) => setDialogState(() => isAvailable = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Action buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final price = double.tryParse(priceController.text);
                          if (nameController.text.isEmpty || price == null || price <= 0 || selectedCategoryId == null) return;
                          final emoji = emojiController.text.isEmpty ? '📦' : emojiController.text;
                          if (isEditing) {
                            vm.updateProduct(
                              existingProduct.id,
                              name: nameController.text,
                              description: descController.text,
                              price: price,
                              categoryId: selectedCategoryId,
                              emoji: emoji,
                              isAvailable: isAvailable,
                            );
                          } else {
                            vm.addProduct(
                              name: nameController.text,
                              price: price,
                              categoryId: selectedCategoryId!,
                              emoji: emoji,
                              description: descController.text,
                              isAvailable: isAvailable,
                            );
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(isEditing ? 'Uložit' : 'Přidat'),
                      ),
                      if (isEditing) ...[
                        const SizedBox(width: Spacing.md),
                        OutlinedButton(
                          onPressed: () {
                            final price = double.tryParse(priceController.text);
                            if (nameController.text.isEmpty || price == null || price <= 0 || selectedCategoryId == null) return;
                            final emoji = emojiController.text.isEmpty ? '📦' : emojiController.text;
                            vm.addProduct(
                              name: nameController.text,
                              price: price,
                              categoryId: selectedCategoryId!,
                              emoji: emoji,
                              description: descController.text,
                              isAvailable: isAvailable,
                            );
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Uložit jako nový'),
                        ),
                      ],
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Zrušit', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

