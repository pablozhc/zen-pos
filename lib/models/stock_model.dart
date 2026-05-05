import 'package:cloud_firestore/cloud_firestore.dart';

enum StockUnit {
  piece('ks'),
  liter('l'),
  milliliter('ml'),
  kilogram('kg'),
  gram('g'),
  portion('porce');

  final String label;
  const StockUnit(this.label);
}

class StockItem {
  final String id;
  String name;
  String? categoryId;
  String? categoryName;
  StockUnit unit;
  double currentStock;
  double? minStock;
  double costPrice;
  String? supplierId;
  String? supplierName;
  bool isArchived;
  bool hasRecipe;
  final DateTime createdAt;

  StockItem({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.unit,
    this.currentStock = 0,
    this.minStock,
    this.costPrice = 0,
    this.supplierId,
    this.supplierName,
    this.isArchived = false,
    this.hasRecipe = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isLowStock => minStock != null && currentStock <= minStock!;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'unit': unit.name,
        'currentStock': currentStock,
        'minStock': minStock,
        'costPrice': costPrice,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'isArchived': isArchived,
        'hasRecipe': hasRecipe,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        id: json['id'],
        name: json['name'],
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        unit: StockUnit.values.byName(json['unit'] ?? 'piece'),
        currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
        minStock: (json['minStock'] as num?)?.toDouble(),
        costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
        supplierId: json['supplierId'],
        supplierName: json['supplierName'],
        isArchived: json['isArchived'] ?? false,
        hasRecipe: json['hasRecipe'] ?? false,
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

enum StockTransactionType {
  receiving('Naskladnění'),
  transfer('Přeskladnění'),
  writeOff('Odpis'),
  saleDeduction('Prodej'),
  inventoryCorrection('Inventurní korekce');

  final String title;
  const StockTransactionType(this.title);
}

class StockTransaction {
  final String id;
  final StockTransactionType type;
  final String stockItemId;
  final String stockItemName;
  final double quantity;
  final double? unitPrice;
  final String? supplierId;
  final String? supplierName;
  final String? targetStockId;
  final String? targetStockName;
  final String? note;
  final String? authorId;
  final String? authorName;
  final DateTime createdAt;

  StockTransaction({
    required this.id,
    required this.type,
    required this.stockItemId,
    required this.stockItemName,
    required this.quantity,
    this.unitPrice,
    this.supplierId,
    this.supplierName,
    this.targetStockId,
    this.targetStockName,
    this.note,
    this.authorId,
    this.authorName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalValue => quantity * (unitPrice ?? 0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'stockItemId': stockItemId,
        'stockItemName': stockItemName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'targetStockId': targetStockId,
        'targetStockName': targetStockName,
        'note': note,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StockTransaction.fromJson(Map<String, dynamic> json) => StockTransaction(
        id: json['id'],
        type: StockTransactionType.values.byName(json['type']),
        stockItemId: json['stockItemId'],
        stockItemName: json['stockItemName'],
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num?)?.toDouble(),
        supplierId: json['supplierId'],
        supplierName: json['supplierName'],
        targetStockId: json['targetStockId'],
        targetStockName: json['targetStockName'],
        note: json['note'],
        authorId: json['authorId'],
        authorName: json['authorName'],
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.parse(json['createdAt']),
      );
}

class InventoryItem {
  final String stockItemId;
  final String stockItemName;
  final double expectedQuantity;
  double actualQuantity;
  final StockUnit unit;

  InventoryItem({
    required this.stockItemId,
    required this.stockItemName,
    required this.expectedQuantity,
    required this.actualQuantity,
    required this.unit,
  });

  double get difference => actualQuantity - expectedQuantity;

  Map<String, dynamic> toJson() => {
        'stockItemId': stockItemId,
        'stockItemName': stockItemName,
        'expectedQuantity': expectedQuantity,
        'actualQuantity': actualQuantity,
        'unit': unit.name,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        stockItemId: json['stockItemId'],
        stockItemName: json['stockItemName'],
        expectedQuantity: (json['expectedQuantity'] as num).toDouble(),
        actualQuantity: (json['actualQuantity'] as num).toDouble(),
        unit: StockUnit.values.byName(json['unit'] ?? 'piece'),
      );
}

enum InventoryStatus { draft, completed, approved }

class Inventory {
  final String id;
  final DateTime createdAt;
  DateTime? completedAt;
  InventoryStatus status;
  List<InventoryItem> items;
  final String? authorId;
  final String? authorName;
  String? note;

  Inventory({
    required this.id,
    DateTime? createdAt,
    this.completedAt,
    this.status = InventoryStatus.draft,
    this.items = const [],
    this.authorId,
    this.authorName,
    this.note,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'status': status.name,
        'items': items.map((i) => i.toJson()).toList(),
        'authorId': authorId,
        'authorName': authorName,
        'note': note,
      };

  factory Inventory.fromJson(Map<String, dynamic> json) => Inventory(
        id: json['id'],
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.parse(json['createdAt']),
        completedAt: json['completedAt'] != null
            ? (json['completedAt'] is Timestamp
                ? (json['completedAt'] as Timestamp).toDate()
                : DateTime.parse(json['completedAt']))
            : null,
        status: InventoryStatus.values.byName(json['status'] ?? 'draft'),
        items: (json['items'] as List? ?? [])
            .map((i) => InventoryItem.fromJson(i))
            .toList(),
        authorId: json['authorId'],
        authorName: json['authorName'],
        note: json['note'],
      );
}

class Supplier {
  final String id;
  String name;
  String? contactName;
  String? phone;
  String? email;
  String? address;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactName': contactName,
        'phone': phone,
        'email': email,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'],
        name: json['name'],
        contactName: json['contactName'],
        phone: json['phone'],
        email: json['email'],
        address: json['address'],
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
