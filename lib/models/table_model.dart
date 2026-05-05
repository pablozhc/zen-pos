import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'order_model.dart';

enum TableStatus {
  free,
  occupied,
  reserved;

  Color get color {
    switch (this) {
      case TableStatus.free:
        return AppColors.statusFree;
      case TableStatus.occupied:
        return AppColors.statusActive;
      case TableStatus.reserved:
        return AppColors.statusReserved;
    }
  }

  String get title {
    switch (this) {
      case TableStatus.free:
        return 'Volný';
      case TableStatus.occupied:
        return 'Obsazeno';
      case TableStatus.reserved:
        return 'Rezervováno';
    }
  }
}

class TableModel {
  final String id;
  final int number;
  TableStatus status;
  Order? currentOrder;
  DateTime? reservedFor;

  TableModel({
    required this.id,
    required this.number,
    this.status = TableStatus.free,
    this.currentOrder,
    this.reservedFor,
  });

  double get displayAmount => currentOrder?.total ?? 0.0;

  int? get elapsedMinutes {
    if (currentOrder == null) return null;
    return DateTime.now().difference(currentOrder!.createdAt).inMinutes;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'status': status.name,
        'currentOrder': currentOrder?.toJson(),
        'reservedFor': reservedFor?.toIso8601String(),
      };

  factory TableModel.fromJson(Map<String, dynamic> json) => TableModel(
        id: json['id'],
        number: json['number'],
        status: TableStatus.values.byName(json['status']),
        currentOrder: json['currentOrder'] != null
            ? Order.fromJson(json['currentOrder'])
            : null,
        reservedFor: json['reservedFor'] != null
            ? DateTime.parse(json['reservedFor'])
            : null,
      );
}
