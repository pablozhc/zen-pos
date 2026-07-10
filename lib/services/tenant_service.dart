import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

/// Správa tenantů: vyhledání podle přihlášeného uživatele, založení nového
/// podniku a jednorázová migrace dat ze starých root kolekcí.
class TenantService {
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Tenant?> findTenantForUser(String uid) async {
    final snap = await _db
        .collection('tenants')
        .where('memberUids', arrayContains: uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Tenant.fromJson(snap.docs.first.id, snap.docs.first.data());
  }

  Future<Tenant> createTenant({
    required String name,
    required String ownerUid,
    String? ownerEmail,
  }) async {
    final doc = _db.collection('tenants').doc();
    final tenant = Tenant(
      id: doc.id,
      name: name,
      ownerUid: ownerUid,
      memberUids: [ownerUid],
      memberEmails: [if (ownerEmail != null) ownerEmail],
      createdAt: DateTime.now().toIso8601String(),
    );
    await doc.set(tenant.toJson());
    return tenant;
  }

  Future<void> addMember(String tenantId, String uid, {String? email}) {
    return _db.collection('tenants').doc(tenantId).update({
      'memberUids': FieldValue.arrayUnion([uid]),
      if (email != null) 'memberEmails': FieldValue.arrayUnion([email]),
    });
  }

  Future<void> renameTenant(String tenantId, String name) {
    return _db.collection('tenants').doc(tenantId).update({'name': name});
  }

}
