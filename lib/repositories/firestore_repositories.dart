import '../models/table_model.dart';
import '../models/payment_model.dart';
import '../models/product_model.dart';
import '../models/staff_model.dart';
import '../services/firestore_service.dart';
import 'tables_repository.dart';
import 'products_repository.dart';
import 'staff_repository.dart';

// ── Concrete Firestore implementations ──────────────────────────────────────
// Swap these out for mock/local implementations in tests or offline mode.

class FirestoreTablesRepository implements TablesRepository {
  final FirestoreService _fs;
  FirestoreTablesRepository(this._fs);

  @override Stream<List<TableModel>> tablesStream()   => _fs.tablesStream();
  @override Stream<List<Payment>>    paymentsStream() => _fs.paymentsStream();
  @override Future<void> setTable(TableModel t)       => _fs.setTable(t);
  @override Future<void> deleteTable(String id)       => _fs.deleteTable(id);
  @override Future<void> addPayment(Payment p)        => _fs.addPayment(p);
  @override Future<bool> isTablesEmpty()              => _fs.isCollectionEmpty('tables');
}

class FirestoreProductsRepository implements ProductsRepository {
  final FirestoreService _fs;
  FirestoreProductsRepository(this._fs);

  @override Stream<List<ProductCategory>> categoriesStream() => _fs.categoriesStream();
  @override Stream<List<Product>>         productsStream()   => _fs.productsStream();
  @override Future<void> setCategory(ProductCategory c)      => _fs.setCategory(c);
  @override Future<void> deleteCategory(String id)           => _fs.deleteCategory(id);
  @override Future<void> setProduct(Product p)               => _fs.setProduct(p);
  @override Future<void> deleteProduct(String id)            => _fs.deleteProduct(id);
  @override Future<bool> isCategoriesEmpty()                 => _fs.isCollectionEmpty('categories');
  @override Future<bool> isProductsEmpty()                   => _fs.isCollectionEmpty('products');
}

class FirestoreStaffRepository implements StaffRepository {
  final FirestoreService _fs;
  FirestoreStaffRepository(this._fs);

  @override Stream<List<StaffRole>>   rolesStream()   => _fs.rolesStream();
  @override Stream<List<StaffMember>> staffStream()   => _fs.staffStream();
  @override Future<void> setRole(StaffRole r)         => _fs.setRole(r);
  @override Future<void> deleteRole(String id)        => _fs.deleteRole(id);
  @override Future<void> setStaff(StaffMember m)      => _fs.setStaff(m);
  @override Future<void> deleteStaff(String id)       => _fs.deleteStaff(id);
  @override Future<StaffMember?> getStaffByUsername(String u) => _fs.getStaffByUsername(u);
  @override Future<StaffMember?> getStaffByFirebaseUid(String u) => _fs.getStaffByFirebaseUid(u);
  @override Future<bool> isRolesEmpty()               => _fs.isCollectionEmpty('roles');
  @override Future<bool> isStaffEmpty()               => _fs.isCollectionEmpty('staff');
}
