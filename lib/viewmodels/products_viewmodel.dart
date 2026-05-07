import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../repositories/products_repository.dart';
import '../repositories/firestore_repositories.dart';
import '../services/firestore_service.dart';

class ProductsViewModel extends ChangeNotifier {
  final ProductsRepository _repo;

  ProductsViewModel([ProductsRepository? repo])
      : _repo = repo ?? FirestoreProductsRepository(FirestoreService()) {
    _initialize();
  }

  List<ProductCategory> _categories = [];
  List<Product> _products = [];

  StreamSubscription? _categoriesSub;
  StreamSubscription? _productsSub;

  List<ProductCategory> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);

  Future<void> _initialize() async {
    if (await _repo.isCategoriesEmpty()) {
      final defaultCategories = [
        ProductCategory(id: 'food', title: 'Jídlo', emoji: '🍔'),
        ProductCategory(id: 'drinks', title: 'Pití', emoji: '🍺'),
        ProductCategory(id: 'desserts', title: 'Dezerty', emoji: '🍰'),
        ProductCategory(id: 'other', title: 'Ostatní', emoji: '📦'),
      ];
      for (final cat in defaultCategories) {
        await _repo.setCategory(cat);
      }
    }

    if (await _repo.isProductsEmpty()) {
      final defaultProducts = [
        Product(id: const Uuid().v4(), name: 'Pivo Pilsner', price: 55, categoryId: 'drinks', emoji: '🍺'),
        Product(id: const Uuid().v4(), name: 'Pivo Radler', price: 60, categoryId: 'drinks', emoji: '🍺'),
        Product(id: const Uuid().v4(), name: 'Červené víno', price: 120, categoryId: 'drinks', emoji: '🍷'),
        Product(id: const Uuid().v4(), name: 'Bílé víno', price: 120, categoryId: 'drinks', emoji: '🍷'),
        Product(id: const Uuid().v4(), name: 'Whiskey', price: 180, categoryId: 'drinks', emoji: '🥃'),
        Product(id: const Uuid().v4(), name: 'Cola', price: 45, categoryId: 'drinks', emoji: '🥤'),
        Product(id: const Uuid().v4(), name: 'Espresso', price: 30, categoryId: 'drinks', emoji: '☕'),
        Product(id: const Uuid().v4(), name: 'Cappuccino', price: 40, categoryId: 'drinks', emoji: '☕'),
        Product(id: const Uuid().v4(), name: 'Burger', price: 180, categoryId: 'food', emoji: '🍔'),
        Product(id: const Uuid().v4(), name: 'Pizza Margherita', price: 220, categoryId: 'food', emoji: '🍕'),
        Product(id: const Uuid().v4(), name: 'Pasta Carbonara', price: 240, categoryId: 'food', emoji: '🍝'),
        Product(id: const Uuid().v4(), name: 'Caesar Salad', price: 160, categoryId: 'food', emoji: '🥗'),
        Product(id: const Uuid().v4(), name: 'Steak', price: 380, categoryId: 'food', emoji: '🥩'),
        Product(id: const Uuid().v4(), name: 'Hranolky', price: 80, categoryId: 'food', emoji: '🍟'),
        Product(id: const Uuid().v4(), name: 'Tiramisu', price: 120, categoryId: 'desserts', emoji: '🍰'),
        Product(id: const Uuid().v4(), name: 'Zmrzlina', price: 90, categoryId: 'desserts', emoji: '🍨'),
        Product(id: const Uuid().v4(), name: 'Čokoládový dort', price: 110, categoryId: 'desserts', emoji: '🍫'),
      ];
      for (final product in defaultProducts) {
        await _repo.setProduct(product);
      }
    }

    // Listen to real-time streams
    _categoriesSub = _repo.categoriesStream().listen((categories) {
      _categories = categories;
      notifyListeners();
    });

    _productsSub = _repo.productsStream().listen((products) {
      _products = products;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _productsSub?.cancel();
    super.dispose();
  }

  // Categories

  ProductCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  void addCategory({required String title, required String emoji}) {
    final category = ProductCategory(
      id: const Uuid().v4(),
      title: title,
      emoji: emoji,
    );
    _categories = [..._categories, category];
    notifyListeners();
    _repo.setCategory(category);
  }

  void deleteCategory(String categoryId) {
    _products = _products.where((p) => p.categoryId != categoryId).toList();
    _categories = _categories.where((c) => c.id != categoryId).toList();
    notifyListeners();
    _repo.deleteCategory(categoryId);
  }

  // Products

  void addProduct({
    required String name,
    required double price,
    required String categoryId,
    required String emoji,
    String description = '',
    bool isAvailable = true,
  }) {
    final product = Product(
      id: const Uuid().v4(),
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      emoji: emoji,
      isAvailable: isAvailable,
    );
    _products = [..._products, product];
    notifyListeners();
    _repo.setProduct(product);
  }

  void updateProduct(String productId, {
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? emoji,
    bool? isAvailable,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return;
    final p = _products[index];
    if (name != null) p.name = name;
    if (description != null) p.description = description;
    if (price != null) p.price = price;
    if (categoryId != null) p.categoryId = categoryId;
    if (emoji != null) p.emoji = emoji;
    if (isAvailable != null) p.isAvailable = isAvailable;
    notifyListeners();
    _repo.setProduct(p);
  }

  void updateProductPrice(String productId, double price) {
    updateProduct(productId, price: price);
  }

  void deleteProduct(String productId) {
    _products = _products.where((p) => p.id != productId).toList();
    notifyListeners();
    _repo.deleteProduct(productId);
  }
}

