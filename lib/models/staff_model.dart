class StaffRole {
  final String id;
  String name;
  List<String> permissions;
  final bool isDefault;

  StaffRole({
    required this.id,
    required this.name,
    required this.permissions,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'permissions': permissions,
        'isDefault': isDefault,
      };

  factory StaffRole.fromJson(Map<String, dynamic> json) => StaffRole(
        id: json['id'],
        name: json['name'],
        permissions: List<String>.from(json['permissions'] ?? []),
        isDefault: json['isDefault'] ?? false,
      );

  bool hasPermission(String permission) => permissions.contains(permission);

  static const allPermissions = {
    'tables': 'Stoly',
    'orders': 'Objednávky',
    'payments': 'Platby',
    'history': 'Historie',
    'reports': 'Report',
    'categories': 'Kategorie',
    'products': 'Produkty',
    'staff': 'Personál',
    'roles': 'Role',
  };
}

class StaffMember {
  final String id;
  String name;
  String pinHash;
  String? username;
  String? passwordHash;
  String? firebaseUid;
  String roleId;
  bool isActive;

  StaffMember({
    required this.id,
    required this.name,
    required this.pinHash,
    this.username,
    this.passwordHash,
    this.firebaseUid,
    required this.roleId,
    this.isActive = true,
  });

  bool get hasAdminAccess => firebaseUid != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pinHash': pinHash,
        'username': username,
        'passwordHash': passwordHash,
        'firebaseUid': firebaseUid,
        'roleId': roleId,
        'isActive': isActive,
      };

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'],
        name: json['name'],
        pinHash: json['pinHash'] ?? '',
        username: json['username'],
        passwordHash: json['passwordHash'],
        firebaseUid: json['firebaseUid'],
        roleId: json['roleId'],
        isActive: json['isActive'] ?? true,
      );
}
