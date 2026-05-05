import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/table_model.dart';
import '../models/payment_model.dart';
import '../models/staff_model.dart';
import '../models/cash_movement_model.dart';
import '../models/stock_model.dart';
import '../models/happy_hour_model.dart';
import '../models/addon_model.dart';
import '../models/pos_settings_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _categoriesRef => _db.collection('categories');
  CollectionReference get _productsRef => _db.collection('products');
  CollectionReference get _tablesRef => _db.collection('tables');
  CollectionReference get _paymentsRef => _db.collection('payments');
  CollectionReference get _cashMovementsRef => _db.collection('cash_movements');
  CollectionReference get _closuresRef => _db.collection('day_closures');
  CollectionReference get _stockItemsRef => _db.collection('stock_items');
  CollectionReference get _stockTransactionsRef => _db.collection('stock_transactions');
  CollectionReference get _inventoriesRef => _db.collection('inventories');
  CollectionReference get _suppliersRef => _db.collection('suppliers');
  CollectionReference get _happyHoursRef => _db.collection('happy_hours');
  CollectionReference get _addonsRef => _db.collection('product_addons');
  DocumentReference get _posSettingsRef =>
      _db.collection('settings').doc('pos_settings');

  // ── Categories ──

  Stream<List<ProductCategory>> categoriesStream() {
    return _categoriesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductCategory(
          id: data['id'],
          title: data['title'],
          emoji: data['emoji'],
        );
      }).toList();
    });
  }

  Future<void> setCategory(ProductCategory category) {
    return _categoriesRef.doc(category.id).set({
      'id': category.id,
      'title': category.title,
      'emoji': category.emoji,
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
    final products = await _productsRef
        .where('categoryId', isEqualTo: categoryId)
        .get();
    for (final doc in products.docs) {
      await doc.reference.delete();
    }
  }

  // ── Products ──

  Stream<List<Product>> productsStream() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromJson(data);
      }).toList();
    });
  }

  Future<void> setProduct(Product product) {
    return _productsRef.doc(product.id).set(product.toJson());
  }

  Future<void> deleteProduct(String productId) {
    return _productsRef.doc(productId).delete();
  }

  // ── Tables ──

  Stream<List<TableModel>> tablesStream() {
    return _tablesRef.orderBy('number').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TableModel.fromJson(data);
      }).toList();
    });
  }

  Future<void> setTable(TableModel table) {
    return _tablesRef.doc('table_${table.number}').set(table.toJson());
  }

  Future<void> deleteTable(String tableId) {
    return _tablesRef.doc(tableId).delete();
  }

  // ── Payments ──

  Stream<List<Payment>> paymentsStream() {
    return _paymentsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Payment.fromJson(data);
      }).toList();
    });
  }

  Future<List<Payment>> getPaymentsInRange(DateTime from, DateTime to) async {
    final snapshot = await _paymentsRef
        .where('timestamp',
            isGreaterThanOrEqualTo: from.toIso8601String(),
            isLessThanOrEqualTo: to.toIso8601String())
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((d) => Payment.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> addPayment(Payment payment) {
    return _paymentsRef.doc(payment.id).set(payment.toJson());
  }

  // ── Roles ──

  CollectionReference get _rolesRef => _db.collection('roles');

  Stream<List<StaffRole>> rolesStream() {
    return _rolesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return StaffRole.fromJson(data);
      }).toList();
    });
  }

  Future<void> setRole(StaffRole role) {
    return _rolesRef.doc(role.id).set(role.toJson());
  }

  Future<void> deleteRole(String roleId) {
    return _rolesRef.doc(roleId).delete();
  }

  // ── Staff ──

  CollectionReference get _staffRef => _db.collection('staff');

  Stream<List<StaffMember>> staffStream() {
    return _staffRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return StaffMember.fromJson(data);
      }).toList();
    });
  }

  Future<void> setStaff(StaffMember member) {
    return _staffRef.doc(member.id).set(member.toJson());
  }

  Future<void> deleteStaff(String staffId) {
    return _staffRef.doc(staffId).delete();
  }

  Future<StaffMember?> getStaffByUsername(String username) async {
    final snapshot = await _staffRef
        .where('username', isEqualTo: username)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return StaffMember.fromJson(
        snapshot.docs.first.data() as Map<String, dynamic>);
  }

  Future<StaffMember?> getStaffByFirebaseUid(String uid) async {
    final snapshot = await _staffRef
        .where('firebaseUid', isEqualTo: uid)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return StaffMember.fromJson(
        snapshot.docs.first.data() as Map<String, dynamic>);
  }

  // ── Cash Movements ──

  Stream<List<CashMovement>> cashMovementsStream({DateTime? from, DateTime? to}) {
    Query query = _cashMovementsRef.orderBy('createdAt', descending: true);
    if (from != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: from.toIso8601String());
    }
    if (to != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: to.toIso8601String());
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((d) => CashMovement.fromJson(d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> addCashMovement(CashMovement movement) {
    return _cashMovementsRef.doc(movement.id).set(movement.toJson());
  }

  Future<void> deleteCashMovement(String id) {
    return _cashMovementsRef.doc(id).delete();
  }

  // ── Day Closures ──

  Stream<List<DayClosure>> closuresStream() {
    return _closuresRef
        .orderBy('closedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => DayClosure.fromJson(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addClosure(DayClosure closure) {
    return _closuresRef.doc(closure.id).set(closure.toJson());
  }

  // ── Stock Items ──

  Stream<List<StockItem>> stockItemsStream({bool includeArchived = false}) {
    Query query = _stockItemsRef.orderBy('name');
    if (!includeArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((d) => StockItem.fromJson(d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> setStockItem(StockItem item) {
    return _stockItemsRef.doc(item.id).set(item.toJson());
  }

  Future<void> deleteStockItem(String id) {
    return _stockItemsRef.doc(id).delete();
  }

  Future<void> updateStockQuantity(String itemId, double delta) async {
    await _stockItemsRef.doc(itemId).update({
      'currentStock': FieldValue.increment(delta),
    });
  }

  // ── Stock Transactions ──

  Stream<List<StockTransaction>> stockTransactionsStream({
    StockTransactionType? type,
    DateTime? from,
    DateTime? to,
  }) {
    Query query = _stockTransactionsRef.orderBy('createdAt', descending: true);
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((d) => StockTransaction.fromJson(d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> addStockTransaction(StockTransaction tx) async {
    await _stockTransactionsRef.doc(tx.id).set(tx.toJson());
    final delta = tx.type == StockTransactionType.receiving ||
            tx.type == StockTransactionType.inventoryCorrection
        ? tx.quantity
        : -tx.quantity;
    await updateStockQuantity(tx.stockItemId, delta);
  }

  // ── Inventories ──

  Stream<List<Inventory>> inventoriesStream() {
    return _inventoriesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => Inventory.fromJson(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> setInventory(Inventory inventory) {
    return _inventoriesRef.doc(inventory.id).set(inventory.toJson());
  }

  Future<void> deleteInventory(String id) {
    return _inventoriesRef.doc(id).delete();
  }

  // ── Suppliers ──

  Stream<List<Supplier>> suppliersStream() {
    return _suppliersRef
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => Supplier.fromJson(d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> setSupplier(Supplier supplier) {
    return _suppliersRef.doc(supplier.id).set(supplier.toJson());
  }

  Future<void> deleteSupplier(String id) {
    return _suppliersRef.doc(id).delete();
  }

  // ── Happy Hours ──

  Stream<List<HappyHour>> happyHoursStream() {
    return _happyHoursRef.snapshots().map((snapshot) => snapshot.docs
        .map((d) => HappyHour.fromJson(d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> setHappyHour(HappyHour hh) {
    return _happyHoursRef.doc(hh.id).set(hh.toJson());
  }

  Future<void> deleteHappyHour(String id) {
    return _happyHoursRef.doc(id).delete();
  }

  // ── Product Addons ──

  Stream<List<ProductAddon>> addonsStream() {
    return _addonsRef.snapshots().map((snapshot) => snapshot.docs
        .map((d) => ProductAddon.fromJson(d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> setAddon(ProductAddon addon) {
    return _addonsRef.doc(addon.id).set(addon.toJson());
  }

  Future<void> deleteAddon(String id) {
    return _addonsRef.doc(id).delete();
  }

  // ── POS Settings ──

  Future<PosSettings> getPosSettings() async {
    final doc = await _posSettingsRef.get();
    if (!doc.exists) return PosSettings();
    return PosSettings.fromJson(doc.data() as Map<String, dynamic>);
  }

  Stream<PosSettings> posSettingsStream() {
    return _posSettingsRef.snapshots().map((doc) {
      if (!doc.exists) return PosSettings();
      return PosSettings.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> savePosSettings(PosSettings settings) {
    return _posSettingsRef.set(settings.toJson());
  }

  // ── Seeding ──

  Future<bool> isCollectionEmpty(String collection) async {
    final snapshot = await _db.collection(collection).limit(1).get();
    return snapshot.docs.isEmpty;
  }
}
