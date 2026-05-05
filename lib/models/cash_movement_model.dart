import 'package:cloud_firestore/cloud_firestore.dart';

enum CashMovementType {
  income('Příjem', true),
  expense('Výdaj', false),
  closureStart('Počáteční stav', true),
  closureEnd('Uzávěrka', false);

  final String title;
  final bool isPositive;
  const CashMovementType(this.title, this.isPositive);
}

class CashMovement {
  final String id;
  final CashMovementType type;
  final double amount;
  final String? note;
  final String? category;
  final String? authorId;
  final String? authorName;
  final DateTime createdAt;
  final bool isPartOfClosure;
  final String? closureId;

  CashMovement({
    required this.id,
    required this.type,
    required this.amount,
    this.note,
    this.category,
    this.authorId,
    this.authorName,
    DateTime? createdAt,
    this.isPartOfClosure = false,
    this.closureId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'note': note,
        'category': category,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'isPartOfClosure': isPartOfClosure,
        'closureId': closureId,
      };

  factory CashMovement.fromJson(Map<String, dynamic> json) => CashMovement(
        id: json['id'],
        type: CashMovementType.values.byName(json['type']),
        amount: (json['amount'] as num).toDouble(),
        note: json['note'],
        category: json['category'],
        authorId: json['authorId'],
        authorName: json['authorName'],
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.parse(json['createdAt']),
        isPartOfClosure: json['isPartOfClosure'] ?? false,
        closureId: json['closureId'],
      );
}

class DayClosure {
  final String id;
  final DateTime openedAt;
  final DateTime closedAt;
  final double openingCash;
  final double closingCash;
  final double totalRevenue;
  final double totalCash;
  final double totalCard;
  final double totalTips;
  final int paymentCount;
  final String? authorId;
  final String? authorName;
  final String? note;

  DayClosure({
    required this.id,
    required this.openedAt,
    required this.closedAt,
    required this.openingCash,
    required this.closingCash,
    required this.totalRevenue,
    required this.totalCash,
    required this.totalCard,
    required this.totalTips,
    required this.paymentCount,
    this.authorId,
    this.authorName,
    this.note,
  });

  double get difference => closingCash - openingCash - totalCash;

  Map<String, dynamic> toJson() => {
        'id': id,
        'openedAt': openedAt.toIso8601String(),
        'closedAt': closedAt.toIso8601String(),
        'openingCash': openingCash,
        'closingCash': closingCash,
        'totalRevenue': totalRevenue,
        'totalCash': totalCash,
        'totalCard': totalCard,
        'totalTips': totalTips,
        'paymentCount': paymentCount,
        'authorId': authorId,
        'authorName': authorName,
        'note': note,
      };

  factory DayClosure.fromJson(Map<String, dynamic> json) => DayClosure(
        id: json['id'],
        openedAt: json['openedAt'] is Timestamp
            ? (json['openedAt'] as Timestamp).toDate()
            : DateTime.parse(json['openedAt']),
        closedAt: json['closedAt'] is Timestamp
            ? (json['closedAt'] as Timestamp).toDate()
            : DateTime.parse(json['closedAt']),
        openingCash: (json['openingCash'] as num).toDouble(),
        closingCash: (json['closingCash'] as num).toDouble(),
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        totalCash: (json['totalCash'] as num).toDouble(),
        totalCard: (json['totalCard'] as num).toDouble(),
        totalTips: (json['totalTips'] as num).toDouble(),
        paymentCount: json['paymentCount'],
        authorId: json['authorId'],
        authorName: json['authorName'],
        note: json['note'],
      );
}
