import '../models/security_guard.dart';

class MockSecurityGuardRepository {
  static final List<SecurityGuard> _guards = [
    SecurityGuard(
      id: 'SG001',
      name: 'Ramesh Kumar',
      mobile: '9000000001',
      email: 'ramesh.guard@example.com',
      gate: 'Gate 1',
      shift: 'Morning',
      isActive: true,
      canAddEntry: true,
      canManagePreApproved: true,
      canViewInsideList: true,
      canViewGateLogs: true,
    ),
    SecurityGuard(
      id: 'SG002',
      name: 'Suresh Patil',
      mobile: '9000000002',
      email: 'suresh.guard@example.com',
      gate: 'Gate 2',
      shift: 'Night',
      isActive: true,
      canAddEntry: true,
      canManagePreApproved: false,
      canViewInsideList: false,
      canViewGateLogs: false,
    ),
  ];

  static List<SecurityGuard> getAllGuards() => List.unmodifiable(_guards);

  static SecurityGuard? findByMobile(String mobile) {
    try {
      return _guards.firstWhere((g) => g.mobile == mobile);
    } catch (_) {
      return null;
    }
  }

  static SecurityGuard? findById(String id) {
    try {
      return _guards.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  static void addGuard(SecurityGuard guard) => _guards.add(guard);

  static void updateAccess(String id, {
    bool? canAddEntry,
    bool? canManagePreApproved,
    bool? canViewInsideList,
    bool? canViewGateLogs,
    bool? isActive,
  }) {
    final guard = _guards.firstWhere((g) => g.id == id);
    if (canAddEntry != null) guard.canAddEntry = canAddEntry;
    if (canManagePreApproved != null) guard.canManagePreApproved = canManagePreApproved;
    if (canViewInsideList != null) guard.canViewInsideList = canViewInsideList;
    if (canViewGateLogs != null) guard.canViewGateLogs = canViewGateLogs;
    if (isActive != null) guard.isActive = isActive;
  }

  static String generateId() => 'SG${(_guards.length + 1).toString().padLeft(3, '0')}';
}
