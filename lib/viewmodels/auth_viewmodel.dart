import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/staff_model.dart';
import '../repositories/staff_repository.dart';
import '../repositories/firestore_repositories.dart';
import '../services/firestore_service.dart';

class AuthViewModel extends ChangeNotifier {
  final StaffRepository _repo;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthViewModel([StaffRepository? repo])
      : _repo = repo ?? FirestoreStaffRepository(FirestoreService()) {
    _initialize();
  }

  List<StaffMember> _staff = [];
  List<StaffRole> _roles = [];
  StaffMember? _currentUser;
  bool _isReady = false;
  final Completer<void> _readyCompleter = Completer<void>();

  StreamSubscription? _staffSub;
  StreamSubscription? _rolesSub;

  List<StaffMember> get staff => List.unmodifiable(_staff);
  List<StaffMember> get activeStaff =>
      _staff.where((s) => s.isActive).toList();
  List<StaffRole> get roles => List.unmodifiable(_roles);
  StaffMember? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isReady => _isReady;

  StaffRole? get currentRole {
    if (_currentUser == null) return null;
    try {
      return _roles.firstWhere((r) => r.id == _currentUser!.roleId);
    } catch (_) {
      return null;
    }
  }

  bool hasPermission(String permission) {
    return currentRole?.hasPermission(permission) ?? false;
  }

  static String hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> _initialize() async {
    // Seed default roles if empty
    if (await _repo.isRolesEmpty()) {
      await _repo.setRole(StaffRole(
        id: 'role_admin',
        name: 'Admin',
        permissions: StaffRole.allPermissions.keys.toList(),
        isDefault: true,
      ));
      await _repo.setRole(StaffRole(
        id: 'role_waiter',
        name: 'Číšník',
        permissions: ['tables', 'orders', 'payments'],
      ));
    }

    // Seed default admin user if empty (without Firebase Auth — user registers via UI)
    if (await _repo.isStaffEmpty()) {
      await _repo.setStaff(StaffMember(
        id: 'staff_admin',
        name: 'Admin',
        pinHash: hashString('0000'),
        roleId: 'role_admin',
      ));
    }

    // Listen to streams
    _rolesSub = _repo.rolesStream().listen((roles) {
      _roles = roles;
      notifyListeners();
    });

    _staffSub = _repo.staffStream().listen((staff) {
      _staff = staff;
      if (!_isReady && staff.isNotEmpty) {
        _isReady = true;
        _readyCompleter.complete();
      }
      notifyListeners();
    });
  }

  Future<void> waitUntilReady() => _readyCompleter.future;

  @override
  void dispose() {
    _staffSub?.cancel();
    _rolesSub?.cancel();
    super.dispose();
  }

  // ── Auth ──

  bool loginWithPin(String staffId, String pin) {
    try {
      final member = _staff.firstWhere((s) => s.id == staffId && s.isActive);
      if (member.pinHash == hashString(pin)) {
        _currentUser = member;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<String?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) return 'Přihlášení selhalo';

      final member = await _repo.getStaffByFirebaseUid(uid);
      if (member == null) {
        await _firebaseAuth.signOut();
        return 'Tento účet není propojen s žádným členem personálu';
      }

      _currentUser = member;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Špatný e-mail nebo heslo';
        case 'user-disabled':
          return 'Účet byl deaktivován';
        case 'too-many-requests':
          return 'Příliš mnoho pokusů. Zkuste to později.';
        default:
          return 'Chyba přihlášení: ${e.message}';
      }
    } catch (_) {
      return 'Neočekávaná chyba při přihlášení';
    }
  }

  static String _generateTempPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%';
    final rng = Random.secure();
    return List.generate(16, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<String?> registerAdmin({
    required String email,
    required String staffId,
  }) async {
    FirebaseApp? tempApp;
    try {
      // Use secondary FirebaseApp to avoid signing out current admin
      tempApp = await Firebase.initializeApp(
        name: 'tempAuth_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final tempPassword = _generateTempPassword();
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );
      final uid = credential.user?.uid;
      if (uid == null) return 'Vytvoření účtu selhalo';

      // Send password reset email so user can set their own password
      await tempAuth.sendPasswordResetEmail(email: email);

      // Link staff record to Firebase Auth user
      final index = _staff.indexWhere((s) => s.id == staffId);
      if (index == -1) return 'Člen personálu nebyl nalezen';

      _staff[index].firebaseUid = uid;
      _staff[index].username = email;
      notifyListeners();
      await _repo.setStaff(_staff[index]);

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'E-mail je již registrován';
        case 'invalid-email':
          return 'Neplatný formát e-mailu';
        default:
          return 'Chyba: ${e.message}';
      }
    } catch (_) {
      return 'Neočekávaná chyba při vytváření účtu';
    } finally {
      await tempApp?.delete();
    }
  }

  void logout() {
    _firebaseAuth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ── Roles CRUD ──

  StaffRole? getRoleById(String id) {
    try {
      return _roles.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void addRole({required String name, required List<String> permissions}) {
    final role = StaffRole(
      id: 'role_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      permissions: permissions,
    );
    _roles = [..._roles, role];
    notifyListeners();
    _repo.setRole(role);
  }

  void updateRole(String roleId, {String? name, List<String>? permissions}) {
    final index = _roles.indexWhere((r) => r.id == roleId);
    if (index == -1) return;
    if (name != null) _roles[index].name = name;
    if (permissions != null) _roles[index].permissions = permissions;
    notifyListeners();
    _repo.setRole(_roles[index]);
  }

  void deleteRole(String roleId) {
    final role = getRoleById(roleId);
    if (role == null || role.isDefault) return;
    _roles = _roles.where((r) => r.id != roleId).toList();
    notifyListeners();
    _repo.deleteRole(roleId);
  }

  // ── Staff CRUD ──

  void addStaffMember({
    required String name,
    required String pin,
    required String roleId,
  }) {
    final member = StaffMember(
      id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      pinHash: hashString(pin),
      roleId: roleId,
    );
    _staff = [..._staff, member];
    notifyListeners();
    _repo.setStaff(member);
  }

  void updateStaffMember(
    String staffId, {
    String? name,
    String? pin,
    String? roleId,
    bool? isActive,
  }) {
    final index = _staff.indexWhere((s) => s.id == staffId);
    if (index == -1) return;
    final member = _staff[index];
    if (name != null) member.name = name;
    if (pin != null) member.pinHash = hashString(pin);
    if (roleId != null) member.roleId = roleId;
    if (isActive != null) member.isActive = isActive;
    notifyListeners();
    _repo.setStaff(member);
  }

  void unlinkAdmin(String staffId) {
    final index = _staff.indexWhere((s) => s.id == staffId);
    if (index == -1) return;
    _staff[index].firebaseUid = null;
    _staff[index].username = null;
    _staff[index].passwordHash = null;
    notifyListeners();
    _repo.setStaff(_staff[index]);
  }

  void deleteStaffMember(String staffId) {
    _staff = _staff.where((s) => s.id != staffId).toList();
    notifyListeners();
    _repo.deleteStaff(staffId);
  }
}

