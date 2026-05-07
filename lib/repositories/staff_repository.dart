import '../models/staff_model.dart';

abstract class StaffRepository {
  Stream<List<StaffRole>> rolesStream();
  Stream<List<StaffMember>> staffStream();

  Future<void> setRole(StaffRole role);
  Future<void> deleteRole(String roleId);
  Future<void> setStaff(StaffMember member);
  Future<void> deleteStaff(String staffId);
  Future<StaffMember?> getStaffByUsername(String username);
  Future<StaffMember?> getStaffByFirebaseUid(String uid);
  Future<bool> isRolesEmpty();
  Future<bool> isStaffEmpty();
}
