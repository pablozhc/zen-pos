class ProductCategory {
  final String id;
  String title;
  String emoji;

  ProductCategory({
    required this.id,
    required this.title,
    required this.emoji,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Product {
  final String id;
  String name;
  String description;
  double price;
  String categoryId;
  String emoji;
  bool isAvailable;

  Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.categoryId,
    required this.emoji,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'emoji': emoji,
        'isAvailable': isAvailable,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        price: (json['price'] as num).toDouble(),
        categoryId: json['categoryId'] ?? '',
        emoji: json['emoji'] ?? '',
        isAvailable: json['isAvailable'] ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
