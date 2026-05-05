import 'package:uuid/uuid.dart';
import '../models/product_model.dart';

class SampleProducts {
  static final List<Product> allProducts = [
    // Drinks
    Product(id: const Uuid().v4(), name: 'Pivo Pilsner', price: 55, categoryId: 'drinks', emoji: '🍺'),
    Product(id: const Uuid().v4(), name: 'Pivo Radler', price: 60, categoryId: 'drinks', emoji: '🍺'),
    Product(id: const Uuid().v4(), name: 'Červené víno', price: 120, categoryId: 'drinks', emoji: '🍷'),
    Product(id: const Uuid().v4(), name: 'Bílé víno', price: 120, categoryId: 'drinks', emoji: '🍷'),
    Product(id: const Uuid().v4(), name: 'Whiskey', price: 180, categoryId: 'drinks', emoji: '🥃'),
    Product(id: const Uuid().v4(), name: 'Cola', price: 45, categoryId: 'drinks', emoji: '🥤'),
    Product(id: const Uuid().v4(), name: 'Espresso', price: 30, categoryId: 'drinks', emoji: '☕'),
    Product(id: const Uuid().v4(), name: 'Cappuccino', price: 40, categoryId: 'drinks', emoji: '☕'),
    // Food
    Product(id: const Uuid().v4(), name: 'Burger', price: 180, categoryId: 'food', emoji: '🍔'),
    Product(id: const Uuid().v4(), name: 'Pizza Margherita', price: 220, categoryId: 'food', emoji: '🍕'),
    Product(id: const Uuid().v4(), name: 'Pasta Carbonara', price: 240, categoryId: 'food', emoji: '🍝'),
    Product(id: const Uuid().v4(), name: 'Caesar Salad', price: 160, categoryId: 'food', emoji: '🥗'),
    Product(id: const Uuid().v4(), name: 'Steak', price: 380, categoryId: 'food', emoji: '🥩'),
    Product(id: const Uuid().v4(), name: 'Hranolky', price: 80, categoryId: 'food', emoji: '🍟'),
    // Desserts
    Product(id: const Uuid().v4(), name: 'Tiramisu', price: 120, categoryId: 'desserts', emoji: '🍰'),
    Product(id: const Uuid().v4(), name: 'Zmrzlina', price: 90, categoryId: 'desserts', emoji: '🍨'),
    Product(id: const Uuid().v4(), name: 'Čokoládový dort', price: 110, categoryId: 'desserts', emoji: '🍫'),
  ];

  static List<Product> getByCategoryId(String categoryId) {
    return allProducts.where((p) => p.categoryId == categoryId).toList();
  }

  static List<Product> get topProducts {
    return [
      allProducts.firstWhere((p) => p.name == 'Pivo Pilsner'),
      allProducts.firstWhere((p) => p.name == 'Burger'),
      allProducts.firstWhere((p) => p.name == 'Espresso'),
      allProducts.firstWhere((p) => p.name == 'Cola'),
      allProducts.firstWhere((p) => p.name == 'Pasta Carbonara'),
      allProducts.firstWhere((p) => p.name == 'Pizza Margherita'),
    ];
  }
}
