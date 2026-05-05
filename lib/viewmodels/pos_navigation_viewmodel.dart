import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/payment_model.dart';

enum POSNavigationState {
  tablesList,
  menu,
  dailyReport,
  history,
  historyDetail,
  manageCategories,
  manageProducts,
  tableDetail,
  categoryProducts,
}

class POSNavigationViewModel extends ChangeNotifier {
  POSNavigationState _state = POSNavigationState.tablesList;
  int? _selectedTableNumber;
  ProductCategory? _selectedCategory;
  Payment? _selectedPayment;

  POSNavigationState get state => _state;
  int? get selectedTableNumber => _selectedTableNumber;
  ProductCategory? get selectedCategory => _selectedCategory;
  Payment? get selectedPayment => _selectedPayment;

  bool get canGoBack => _state != POSNavigationState.tablesList;

  void selectTable(int tableNumber) {
    _selectedTableNumber = tableNumber;
    _state = POSNavigationState.tableDetail;
    notifyListeners();
  }

  void selectCategory(ProductCategory category) {
    _selectedCategory = category;
    _state = POSNavigationState.categoryProducts;
    notifyListeners();
  }

  void openMenu() {
    _state = POSNavigationState.menu;
    notifyListeners();
  }

  void openDailyReport() {
    _state = POSNavigationState.dailyReport;
    notifyListeners();
  }

  void openHistory() {
    _state = POSNavigationState.history;
    _selectedPayment = null;
    notifyListeners();
  }

  void openManageCategories() {
    _state = POSNavigationState.manageCategories;
    notifyListeners();
  }

  void openManageProducts() {
    _state = POSNavigationState.manageProducts;
    notifyListeners();
  }

  void selectPayment(Payment payment) {
    _selectedPayment = payment;
    _state = POSNavigationState.historyDetail;
    notifyListeners();
  }

  void goBack() {
    switch (_state) {
      case POSNavigationState.categoryProducts:
        _selectedCategory = null;
        _state = POSNavigationState.tableDetail;
        break;
      case POSNavigationState.tableDetail:
        _selectedTableNumber = null;
        _selectedCategory = null;
        _state = POSNavigationState.tablesList;
        break;
      case POSNavigationState.menu:
        _state = POSNavigationState.tablesList;
        break;
      case POSNavigationState.dailyReport:
      case POSNavigationState.history:
      case POSNavigationState.manageCategories:
      case POSNavigationState.manageProducts:
        _selectedPayment = null;
        _state = POSNavigationState.menu;
        break;
      case POSNavigationState.historyDetail:
        _selectedPayment = null;
        _state = POSNavigationState.history;
        break;
      case POSNavigationState.tablesList:
        break;
    }
    notifyListeners();
  }

  void reset() {
    _selectedTableNumber = null;
    _selectedCategory = null;
    _selectedPayment = null;
    _state = POSNavigationState.tablesList;
    notifyListeners();
  }
}
