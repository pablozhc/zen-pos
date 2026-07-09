import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

/// Správa tenantů: vyhledání podle přihlášeného uživatele, založení nového
/// podniku a jednorázová migrace dat ze starých root kolekcí.
class TenantService {
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Root kolekce z doby před multi-tenancy. Drženo v synchronu
  /// s legacy blokem ve firestore.rules.
  static const List<String> legacyCollections = [
    'categories', 'products', 'tables', 'payments', 'staff', 'roles',
    'cash_movements', 'day_closures', 'stock_items', 'stock_transactions',
    'inventories', 'suppliers', 'happy_hours', 'product_addons', 'settings',
  ];

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

  Future<bool> legacyDataExists() async {
    for (final name in ['products', 'staff', 'payments']) {
      final snap = await _db.collection(name).limit(1).get();
      if (snap.docs.isNotEmpty) return true;
    }
    return false;
  }

  /// Zkopíruje všechny legacy root kolekce do subkolekcí tenanta.
  /// Idempotentní (set přepíše stejná ID), root data nechává beze změny —
  /// smazání proběhne ručně až po ověření.
  Future<int> migrateLegacyData(String tenantId) async {
    final tenantRef = _db.collection('tenants').doc(tenantId);
    int copied = 0;
    for (final name in legacyCollections) {
      final snap = await _db.collection(name).get();
      if (snap.docs.isEmpty) continue;
      WriteBatch batch = _db.batch();
      int inBatch = 0;
      for (final d in snap.docs) {
        batch.set(tenantRef.collection(name).doc(d.id), d.data());
        copied++;
        inBatch++;
        if (inBatch == 450) {
          await batch.commit();
          batch = _db.batch();
          inBatch = 0;
        }
      }
      if (inBatch > 0) await batch.commit();
    }
    return copied;
  }
}
