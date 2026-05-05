import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/table_model.dart';
import '../models/payment_model.dart';
import '../viewmodels/tables_viewmodel.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/primary_button.dart';
import '../utils/currency_formatter.dart';
import '../services/printer_service.dart';

class PaymentScreen extends StatefulWidget {
  final TableModel table;

  const PaymentScreen({
    super.key,
    required this.table,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selectedMethod;
  double _tipPercentage = 0;
  final TextEditingController _customTipController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountReasonController = TextEditingController();
  bool _showDiscountPanel = false;

  @override
  void dispose() {
    _customTipController.dispose();
    _discountController.dispose();
    _discountReasonController.dispose();
    super.dispose();
  }

  double get _discountAmount {
    return double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0;
  }

  double get _total {
    final base = widget.table.currentOrder?.subtotal ?? 0;
    return (base - _discountAmount).clamp(0, double.infinity);
  }

  double get _tipAmount {
    if (_customTipController.text.isNotEmpty) {
      return double.tryParse(_customTipController.text) ?? 0;
    }
    return _total * _tipPercentage;
  }

  double get _totalWithTip => _total + _tipAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            // Header (no back button)
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              color: AppColors.background,
              child: Row(
                children: [
                  Text(
                    'PLATBA - STŮL ${widget.table.number}',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            CurrencyFormatter.format(_total),
                            style: AppTypography.displayMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_tipAmount > 0) ...[
                            const SizedBox(height: Spacing.xs),
                            Text(
                              '+ ${CurrencyFormatter.format(_tipAmount)} spropitné',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              '= ${CurrencyFormatter.format(_totalWithTip)}',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: Spacing.xxl),

                    // Discount row
                    Row(
                      children: [
                        Text('SLEVA',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.textSecondary)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(
                              () => _showDiscountPanel = !_showDiscountPanel),
                          icon: Icon(
                              _showDiscountPanel
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18),
                          label: Text(_showDiscountPanel ? 'Skrýt' : 'Přidat'),
                        ),
                      ],
                    ),
                    if (_showDiscountPanel) ...[
                      const SizedBox(height: Spacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _discountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'Částka slevy',
                                suffixText: 'Kč',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _discountReasonController,
                              decoration: const InputDecoration(
                                  hintText: 'Důvod (volitelné)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],

                    const SizedBox(height: Spacing.md),
                    Text(
                      'ZPŮSOB PLATBY',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildPaymentMethods(),

                    const SizedBox(height: Spacing.xl),

                    Text(
                      'SPROPITNÉ',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildTipOptions(),
                  ],
                ),
              ),
            ),

            // Bottom bar - same layout as unified screen
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Row(
      children: [
        // Left (1/3) - ZPĚT
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            color: AppColors.background,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                'ZPĚT',
                style: AppTypography.labelLarge,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.backgroundTertiary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ),
        ),
        // Right (2/3) - POTVRDIT PLATBU
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            color: AppColors.backgroundSecondary,
            child: ElevatedButton.icon(
              onPressed: _selectedMethod != null ? () => _processPayment(context) : null,
              icon: Icon(
                Icons.check_circle,
                color: _selectedMethod != null ? Colors.white : AppColors.textTertiary,
              ),
              label: Text(
                _selectedMethod != null ? 'POTVRDIT PLATBU' : 'VYBERTE ZPŮSOB PLATBY',
                style: AppTypography.labelLarge.copyWith(
                  color: _selectedMethod != null ? Colors.white : AppColors.textTertiary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedMethod != null ? AppColors.primary : AppColors.backgroundTertiary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
                disabledBackgroundColor: AppColors.backgroundTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Row(
      children: [
        Expanded(
          child: _buildPaymentMethodCard(
            PaymentMethod.card,
            '💳',
            _selectedMethod == PaymentMethod.card,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _buildPaymentMethodCard(
            PaymentMethod.cash,
            '💵',
            _selectedMethod == PaymentMethod.cash,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethod method,
    String emoji,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(CornerRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: Spacing.xs),
            Text(
              method.title,
              style: AppTypography.labelLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipOptions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTipButton('10%', 0.10)),
            const SizedBox(width: Spacing.sm),
            Expanded(child: _buildTipButton('15%', 0.15)),
            const SizedBox(width: Spacing.sm),
            Expanded(child: _buildTipButton('20%', 0.20)),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(CornerRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTipController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Vlastní částka',
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (_) {
                    setState(() {
                      _tipPercentage = 0;
                    });
                  },
                ),
              ),
              Text(
                'Kč',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipButton(String label, double percentage) {
    final isSelected = _tipPercentage == percentage &&
        _customTipController.text.isEmpty;
    final amount = _total * percentage;

    return InkWell(
      onTap: () {
        setState(() {
          _tipPercentage = percentage;
          _customTipController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(CornerRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.h4.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.xxs),
            Text(
              '+${CurrencyFormatter.format(amount)}',
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment(BuildContext context) {
    if (_selectedMethod == null || widget.table.currentOrder == null) return;

    final order = widget.table.currentOrder!;
    final receiptItems = order.items.map((item) => ReceiptItem(
      productId: item.product.id,
      productName: item.product.name,
      quantity: item.quantity,
      unitPrice: item.product.price,
      addons: item.selectedAddons,
      note: item.note,
    )).toList();

    final payment = Payment(
      id: const Uuid().v4(),
      orderId: order.id,
      tableNumber: widget.table.number,
      amount: _total,
      method: _selectedMethod!,
      tip: _tipAmount,
      discount: _discountAmount,
      discountReason: _discountReasonController.text.isNotEmpty
          ? _discountReasonController.text
          : null,
      items: receiptItems,
      personCount: order.personCount,
      staffId: order.staffId,
      staffName: order.staffName,
      receiptNumber: 'PA${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );

    _showPaymentSuccess(context, payment);
  }

  void _showPaymentSuccess(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(Spacing.xl),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(CornerRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'ZAPLACENO',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                CurrencyFormatter.format(payment.totalWithTip),
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (payment.tip > 0) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  'Spropitné: +${CurrencyFormatter.format(payment.tip)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.sm),
              Text(
                'Stůl ${widget.table.number} je nyní volný',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              PrimaryButton(
                title: 'HOTOVO',
                onPressed: () {
                  final viewModel = context.read<TablesViewModel>();
                  viewModel.addPayment(payment);

                  // Tisk účtenky (na pozadí, neblokuje)
                  final printer = context.read<PrinterService>();
                  if (printer.isConnected) {
                    printer.printReceipt(
                      payment: payment,
                      order: widget.table.currentOrder!,
                      tableNumber: widget.table.number,
                    );
                  }

                  viewModel.freeTable(widget.table.number);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                height: 54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
