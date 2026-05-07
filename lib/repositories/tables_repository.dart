import '../models/table_model.dart';
import '../models/payment_model.dart';

abstract class TablesRepository {
  Stream<List<TableModel>> tablesStream();
  Stream<List<Payment>> paymentsStream();

  Future<void> setTable(TableModel table);
  Future<void> deleteTable(String tableId);
  Future<void> addPayment(Payment payment);
  Future<bool> isTablesEmpty();
}
