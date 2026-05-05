class AddonOption {
  final String id;
  String name;
  double extraPrice;

  AddonOption({
    required this.id,
    required this.name,
    this.extraPrice = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'extraPrice': extraPrice,
      };

  factory AddonOption.fromJson(Map<String, dynamic> json) => AddonOption(
        id: json['id'],
        name: json['name'],
        extraPrice: (json['extraPrice'] as num?)?.toDouble() ?? 0,
      );
}

class ProductAddon {
  final String id;
  String name;
  bool isRequired;
  bool multiSelect;
  List<AddonOption> options;
  List<String> productIds; // empty = applies to all
  List<String> categoryIds;

  ProductAddon({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.multiSelect = false,
    this.options = const [],
    this.productIds = const [],
    this.categoryIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isRequired': isRequired,
        'multiSelect': multiSelect,
        'options': options.map((o) => o.toJson()).toList(),
        'productIds': productIds,
        'categoryIds': categoryIds,
      };

  factory ProductAddon.fromJson(Map<String, dynamic> json) => ProductAddon(
        id: json['id'],
        name: json['name'],
        isRequired: json['isRequired'] ?? false,
        multiSelect: json['multiSelect'] ?? false,
        options: (json['options'] as List? ?? [])
            .map((o) => AddonOption.fromJson(o))
            .toList(),
        productIds: List<String>.from(json['productIds'] ?? []),
        categoryIds: List<String>.from(json['categoryIds'] ?? []),
      );
}

class SelectedAddon {
  final String addonId;
  final String addonName;
  final String optionId;
  final String optionName;
  final double extraPrice;

  const SelectedAddon({
    required this.addonId,
    required this.addonName,
    required this.optionId,
    required this.optionName,
    required this.extraPrice,
  });

  Map<String, dynamic> toJson() => {
        'addonId': addonId,
        'addonName': addonName,
        'optionId': optionId,
        'optionName': optionName,
        'extraPrice': extraPrice,
      };

  factory SelectedAddon.fromJson(Map<String, dynamic> json) => SelectedAddon(
        addonId: json['addonId'],
        addonName: json['addonName'],
        optionId: json['optionId'],
        optionName: json['optionName'],
        extraPrice: (json['extraPrice'] as num?)?.toDouble() ?? 0,
      );
}
