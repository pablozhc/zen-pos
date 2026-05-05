import 'product_model.dart';
import 'addon_model.dart';

enum OrderStatus {
  active,
  paid,
  cancelled;
}

class Order {
  final String id;
  int tableNumber;
  List<OrderItem> items;
  final DateTime createdAt;
  OrderStatus status;
  double discountAmount;
  String? discountReason;
  int personCount;
  String? staffId;
  String? staffName;

  Order({
    required this.id,
    required this.tableNumber,
    this.items = const [],
    DateTime? createdAt,
    this.status = OrderStatus.active,
    this.discountAmount = 0.0,
    this.discountReason,
    this.personCount = 1,
    this.staffId,
    this.staffName,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get vat => subtotal * 0.21;

  double get total => (subtotal - discountAmount).clamp(0, double.infinity);

  List<String> get itemsPreview =>
      items.take(3).map((item) => item.product.name).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableNumber': tableNumber,
        'items': items.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'discountAmount': discountAmount,
        'discountReason': discountReason,
        'personCount': personCount,
        'staffId': staffId,
        'staffName': staffName,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        tableNumber: json['tableNumber'],
        items: (json['items'] as List)
            .map((item) => OrderItem.fromJson(item))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        status: OrderStatus.values.byName(json['status']),
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
        discountReason: json['discountReason'],
        personCount: json['personCount'] ?? 1,
        staffId: json['staffId'],
        staffName: json['staffName'],
      );
}

class OrderItem {
  final String id;
  final Product product;
  int quantity;
  String? note;
  final DateTime timestamp;
  List<SelectedAddon> selectedAddons;
  bool isStorno;
  String? stornoReason;

  OrderItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.note,
    DateTime? timestamp,
    this.selectedAddons = const [],
    this.isStorno = false,
    this.stornoReason,
  }) : timestamp = timestamp ?? DateTime.now();

  double get unitPrice =>
      product.price +
      selectedAddons.fold(0.0, (s, a) => s + a.extraPrice);

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product.toJson(),
        'quantity': quantity,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
        'selectedAddons': selectedAddons.map((a) => a.toJson()).toList(),
        'isStorno': isStorno,
        'stornoReason': stornoReason,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'],
        product: Product.fromJson(json['product']),
        quantity: json['quantity'],
        note: json['note'],
        timestamp: DateTime.parse(json['timestamp']),
        selectedAddons: (json['selectedAddons'] as List? ?? [])
            .map((a) => SelectedAddon.fromJson(a))
            .toList(),
        isStorno: json['isStorno'] ?? false,
        stornoReason: json['stornoReason'],
      );
}
