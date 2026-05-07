import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/payment_model.dart';
import '../models/addon_model.dart';
import '../repositories/tables_repository.dart';
import '../repositories/firestore_repositories.dart';
import '../services/firestore_service.dart';

class TablesViewModel extends ChangeNotifier {
  final TablesRepository _repo;

  TablesViewModel([TablesRepository? repo])
      : _repo = repo ?? FirestoreTablesRepository(FirestoreService()) {
    _initialize();
  }

  List<TableModel> _tables = [];
  List<Payment> _paymentHistory = [];
  bool _showFreeTables = false;
  TableModel? _selectedTable;
  int? _preselectedTableNumber;

  StreamSubscription? _tablesSub;
  StreamSubscription? _paymentsSub;

  List<TableModel> get allTables => _tables;
  List<TableModel> get activeTables => _tables.where((t) => t.status == TableStatus.occupied).toList();
  List<TableModel> get freeTables   => _tables.where((t) => t.status == TableStatus.free).toList();
  bool get showFreeTables => _showFreeTables;
  TableModel? get selectedTable => _selectedTable;
  int? get preselectedTable => _preselectedTableNumber;
  int get todayOrders => activeTables.length;
  double get todayRevenue => activeTables.fold(0.0, (sum, t) => sum + t.displayAmount);

  Future<void> _initialize() async {
    if (await _repo.isTablesEmpty()) {
      for (int i = 1; i <= 10; i++) {
        final table = TableModel(
          id: 'table_$i',
          number: i,
          status: TableStatus.free,
        );
        await _repo.setTable(table);
      }
    }

    // Listen to real-time streams
    _tablesSub = _repo.tablesStream().listen((tables) {
      _tables = tables;

      // Refresh selected table reference
      if (_selectedTable != null) {
        try {
          _selectedTable = _tables.firstWhere(
            (t) => t.number == _selectedTable!.number,
          );
        } catch (_) {
          _selectedTable = null;
        }
      }

      notifyListeners();
    });

    _paymentsSub = _repo.paymentsStream().listen((payments) {
      _paymentHistory = payments;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tablesSub?.cancel();
    _paymentsSub?.cancel();
    super.dispose();
  }

  void toggleShowFreeTables() {
    _showFreeTables = !_showFreeTables;
    notifyListeners();
  }

  set selectedTable(TableModel? table) {
    _selectedTable = table;
    notifyListeners();
  }

  set preselectedTable(int? tableNumber) {
    _preselectedTableNumber = tableNumber;
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  void quickPayment(TableModel table) {
    debugPrint('Quick payment for table ${table.number}');
  }

  TableModel? getTableByNumber(int number) {
    try {
      return _tables.firstWhere((t) => t.number == number);
    } catch (e) {
      return null;
    }
  }

  void updateTable(TableModel table) {
    final index = _tables.indexWhere((t) => t.id == table.id);
    if (index != -1) {
      _tables[index] = table;
      notifyListeners();
      _repo.setTable(table);
    }
  }

  // Payment history
  List<Payment> get paymentHistory => List.unmodifiable(_paymentHistory);

  List<Payment> get todayPayments {
    final now = DateTime.now();
    return _paymentHistory
        .where((p) =>
            p.timestamp.year == now.year &&
            p.timestamp.month == now.month &&
            p.timestamp.day == now.day)
        .toList();
  }

  double get todayCompletedRevenue =>
      todayPayments.fold(0.0, (sum, p) => sum + p.totalWithTip);

  double get openTabsTotal =>
      activeTables.fold(0.0, (sum, t) => sum + t.displayAmount);

  void addPayment(Payment payment) {
    _paymentHistory = [payment, ..._paymentHistory];
    notifyListeners();
    _repo.addPayment(payment);
  }

  void freeTable(int tableNumber) {
    final table = getTableByNumber(tableNumber);
    if (table != null) {
      table.status = TableStatus.free;
      table.currentOrder = null;
      notifyListeners();
      _repo.setTable(table);
    }
  }

  void addProductToTable(int tableNumber, Product product,
      {List<SelectedAddon>? addons, String? note}) {
    final table = getTableByNumber(tableNumber);
    if (table == null) return;

    if (table.currentOrder == null) {
      table.currentOrder = Order(
        id: const Uuid().v4(),
        tableNumber: tableNumber,
        items: [],
        createdAt: DateTime.now(),
      );
      table.status = TableStatus.occupied;
    }

    // Only merge if no addons/note (otherwise always new line)
    final hasCustomization = (addons != null && addons.isNotEmpty) || note != null;
    final existingItemIndex = hasCustomization ? -1 : table.currentOrder!.items.indexWhere(
      (item) => item.product.id == product.id && !item.isStorno && item.selectedAddons.isEmpty && item.note == null,
    );

    if (existingItemIndex != -1) {
      final existingItem = table.currentOrder!.items[existingItemIndex];
      table.currentOrder!.items[existingItemIndex] = OrderItem(
        id: existingItem.id,
        product: existingItem.product,
        quantity: existingItem.quantity + 1,
        note: existingItem.note,
        timestamp: existingItem.timestamp,
      );
    } else {
      table.currentOrder!.items.add(OrderItem(
        id: const Uuid().v4(),
        product: product,
        quantity: 1,
        timestamp: DateTime.now(),
        selectedAddons: addons ?? [],
        note: note,
      ));
    }

    notifyListeners();
    _repo.setTable(table);
  }

  void updateOrderItemQuantity(int tableNumber, String itemId, int newQuantity) {
    final table = getTableByNumber(tableNumber);
    if (table == null || table.currentOrder == null) return;

    final itemIndex = table.currentOrder!.items.indexWhere(
      (item) => item.id == itemId,
    );

    if (itemIndex == -1) return;

    if (newQuantity <= 0) {
      // Remove item if quantity is 0 or less
      table.currentOrder!.items.removeAt(itemIndex);

      // Free table if no items left
      if (table.currentOrder!.items.isEmpty) {
        table.status = TableStatus.free;
        table.currentOrder = null;
      }
    } else {
      // Update quantity
      final existingItem = table.currentOrder!.items[itemIndex];
      table.currentOrder!.items[itemIndex] = OrderItem(
        id: existingItem.id,
        product: existingItem.product,
        quantity: newQuantity,
        note: existingItem.note,
        timestamp: existingItem.timestamp,
      );
    }

    notifyListeners();
    _repo.setTable(table);
  }

  void deleteOrderItem(int tableNumber, String itemId) {
    final table = getTableByNumber(tableNumber);
    if (table == null || table.currentOrder == null) return;

    table.currentOrder!.items.removeWhere((item) => item.id == itemId);

    if (table.currentOrder!.items.isEmpty) {
      table.status = TableStatus.free;
      table.currentOrder = null;
    }

    notifyListeners();
    _repo.setTable(table);
  }

  void stornoItem(int tableNumber, String itemId, {String? reason}) {
    final table = getTableByNumber(tableNumber);
    if (table == null || table.currentOrder == null) return;

    final idx = table.currentOrder!.items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return;

    final existing = table.currentOrder!.items[idx];
    table.currentOrder!.items[idx] = OrderItem(
      id: existing.id,
      product: existing.product,
      quantity: existing.quantity,
      note: existing.note,
      timestamp: existing.timestamp,
      selectedAddons: existing.selectedAddons,
      isStorno: true,
      stornoReason: reason,
    );

    notifyListeners();
    _repo.setTable(table);
  }

  void setDiscount(int tableNumber, double amount, String? reason) {
    final table = getTableByNumber(tableNumber);
    if (table == null || table.currentOrder == null) return;

    table.currentOrder!.discountAmount = amount;
    table.currentOrder!.discountReason = reason;

    notifyListeners();
    _repo.setTable(table);
  }

  void setPersonCount(int tableNumber, int count) {
    final table = getTableByNumber(tableNumber);
    if (table == null) return;

    if (table.currentOrder == null) {
      table.currentOrder = Order(
        id: const Uuid().v4(),
        tableNumber: tableNumber,
        items: [],
        createdAt: DateTime.now(),
        personCount: count,
      );
      table.status = TableStatus.occupied;
    } else {
      table.currentOrder!.personCount = count;
    }

    notifyListeners();
    _repo.setTable(table);
  }

  // Alias used by admin sections
  List<TableModel> get tables => _tables;
}

