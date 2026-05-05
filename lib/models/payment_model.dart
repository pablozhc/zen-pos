import 'package:cloud_firestore/cloud_firestore.dart';
import 'addon_model.dart';

enum PaymentMethod {
  card('Karta', 'credit_card'),
  cash('Hotovost', 'payments'),
  transfer('Převodem', 'account_balance');

  final String title;
  final String icon;
  const PaymentMethod(this.title, this.icon);
}

class StornoRecord {
  final String itemId;
  final String productName;
  final int quantity;
  final double amount;
  final String? reason;
  final String? authorId;
  final String? authorName;
  final DateTime timestamp;

  StornoRecord({
    required this.itemId,
    required this.productName,
    required this.quantity,
    required this.amount,
    this.reason,
    this.authorId,
    this.authorName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'productName': productName,
        'quantity': quantity,
        'amount': amount,
        'reason': reason,
        'authorId': authorId,
        'authorName': authorName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory StornoRecord.fromJson(Map<String, dynamic> json) => StornoRecord(
        itemId: json['itemId'],
        productName: json['productName'],
        quantity: json['quantity'],
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'],
        authorId: json['authorId'],
        authorName: json['authorName'],
        timestamp: json['timestamp'] is Timestamp
            ? (json['timestamp'] as Timestamp).toDate()
            : DateTime.parse(json['timestamp']),
      );
}

class ReceiptItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final List<SelectedAddon> addons;
  final String? note;

  const ReceiptItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.addons = const [],
    this.note,
  });

  double get totalPrice =>
      (unitPrice + addons.fold(0.0, (s, a) => s + a.extraPrice)) * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'addons': addons.map((a) => a.toJson()).toList(),
        'note': note,
      };

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        productId: json['productId'],
        productName: json['productName'],
        quantity: json['quantity'],
        unitPrice: (json['unitPrice'] as num).toDouble(),
        addons: (json['addons'] as List? ?? [])
            .map((a) => SelectedAddon.fromJson(a))
            .toList(),
        note: json['note'],
      );
}

class Payment {
  final String id;
  final String orderId;
  final int tableNumber;
  final String? tableName;
  final double amount;
  final PaymentMethod method;
  final double tip;
  final double discount;
  final String? discountReason;
  final DateTime timestamp;
  final String? staffId;
  final String? staffName;
  final List<ReceiptItem> items;
  final List<StornoRecord> stornos;
  final int personCount;
  final String? receiptNumber;
  final bool isClosed;

  Payment({
    required this.id,
    required this.orderId,
    required this.tableNumber,
    this.tableName,
    required this.amount,
    required this.method,
    this.tip = 0.0,
    this.discount = 0.0,
    this.discountReason,
    DateTime? timestamp,
    this.staffId,
    this.staffName,
    this.items = const [],
    this.stornos = const [],
    this.personCount = 1,
    this.receiptNumber,
    this.isClosed = false,
  }) : timestamp = timestamp ?? DateTime.now();

  double get totalWithTip => amount + tip;
  double get subtotal => amount + discount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'tableNumber': tableNumber,
        'tableName': tableName,
        'amount': amount,
        'method': method.name,
        'tip': tip,
        'discount': discount,
        'discountReason': discountReason,
        'timestamp': timestamp.toIso8601String(),
        'staffId': staffId,
        'staffName': staffName,
        'items': items.map((i) => i.toJson()).toList(),
        'stornos': stornos.map((s) => s.toJson()).toList(),
        'personCount': personCount,
        'receiptNumber': receiptNumber,
        'isClosed': isClosed,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        orderId: json['orderId'],
        tableNumber: json['tableNumber'],
        tableName: json['tableName'],
        amount: (json['amount'] as num).toDouble(),
        method: PaymentMethod.values.byName(json['method']),
        tip: (json['tip'] as num?)?.toDouble() ?? 0.0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        discountReason: json['discountReason'],
        timestamp: json['timestamp'] is Timestamp
            ? (json['timestamp'] as Timestamp).toDate()
            : DateTime.parse(json['timestamp']),
        staffId: json['staffId'],
        staffName: json['staffName'],
        items: (json['items'] as List? ?? [])
            .map((i) => ReceiptItem.fromJson(i))
            .toList(),
        stornos: (json['stornos'] as List? ?? [])
            .map((s) => StornoRecord.fromJson(s))
            .toList(),
        personCount: json['personCount'] ?? 1,
        receiptNumber: json['receiptNumber'],
        isClosed: json['isClosed'] ?? false,
      );
}
