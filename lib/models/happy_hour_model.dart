class HappyHour {
  final String id;
  String name;
  List<int> weekdays; // 1=Po, 2=Út, ... 7=Ne
  TimeOfDay startTime;
  TimeOfDay endTime;
  HappyHourDiscountType discountType;
  double discountValue; // % or fixed Kč
  List<String> productIds; // empty = all products
  List<String> categoryIds; // empty = all categories
  bool isActive;

  HappyHour({
    required this.id,
    required this.name,
    required this.weekdays,
    required this.startTime,
    required this.endTime,
    required this.discountType,
    required this.discountValue,
    this.productIds = const [],
    this.categoryIds = const [],
    this.isActive = true,
  });

  bool isActiveNow() {
    if (!isActive) return false;
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mo ... 7=Su
    if (!weekdays.contains(weekday)) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  double applyDiscount(double price) {
    if (discountType == HappyHourDiscountType.percentage) {
      return price * (1 - discountValue / 100);
    } else {
      return (price - discountValue).clamp(0, double.infinity);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weekdays': weekdays,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'discountType': discountType.name,
        'discountValue': discountValue,
        'productIds': productIds,
        'categoryIds': categoryIds,
        'isActive': isActive,
      };

  factory HappyHour.fromJson(Map<String, dynamic> json) => HappyHour(
        id: json['id'],
        name: json['name'],
        weekdays: List<int>.from(json['weekdays'] ?? []),
        startTime: TimeOfDay(
          hour: json['startHour'] ?? 0,
          minute: json['startMinute'] ?? 0,
        ),
        endTime: TimeOfDay(
          hour: json['endHour'] ?? 0,
          minute: json['endMinute'] ?? 0,
        ),
        discountType:
            HappyHourDiscountType.values.byName(json['discountType'] ?? 'percentage'),
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
        productIds: List<String>.from(json['productIds'] ?? []),
        categoryIds: List<String>.from(json['categoryIds'] ?? []),
        isActive: json['isActive'] ?? true,
      );
}

enum HappyHourDiscountType {
  percentage('% sleva'),
  fixed('Fixní Kč');

  final String label;
  const HappyHourDiscountType(this.label);
}

class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});

  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  String toString() => format();

  @override
  bool operator ==(Object other) =>
      other is TimeOfDay && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => hour * 60 + minute;
}
