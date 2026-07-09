/// Podnik (tenant) — root multi-tenant dokument.
/// Veškerá provozní data žijí v subkolekcích `tenants/{id}/...`;
/// členství řídí Firestore rules přes `memberUids`.
class Tenant {
  final String id;
  String name;
  final String ownerUid;
  final List<String> memberUids;
  final List<String> memberEmails;
  final String createdAt;

  Tenant({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberUids,
    this.memberEmails = const [],
    required this.createdAt,
  });

  factory Tenant.fromJson(String id, Map<String, dynamic> json) {
    return Tenant(
      id: id,
      name: json['name'] ?? 'Můj podnik',
      ownerUid: json['ownerUid'] ?? '',
      memberUids: List<String>.from(json['memberUids'] ?? []),
      memberEmails: List<String>.from(json['memberEmails'] ?? []),
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'ownerUid': ownerUid,
        'memberUids': memberUids,
        'memberEmails': memberEmails,
        'createdAt': createdAt,
      };
}
