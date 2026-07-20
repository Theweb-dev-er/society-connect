import '../models/resident.dart';
import '../../../subscription/data/models/society.dart';
import '../../../subscription/data/repository/mock_society_repository.dart';

class MockResidentRepository {
  static final List<Resident> _residents = [
    Resident(
      id: 'R001',
      name: 'Rajesh Sharma',
      flatNumber: '101',
      wing: 'Wing A',
      mobile: '9876543210',
      email: 'rajesh@example.com',
      isOwner: true,
      isAdmin: true,
    ),
    Resident(
      id: 'R002',
      name: 'Sunita Patel',
      flatNumber: '102',
      wing: 'Wing A',
      mobile: '9876543214',
      email: 'sunita@example.com',
      isChecker: true,
    ),
    Resident(
      id: 'R003',
      name: 'Vikram Rao',
      flatNumber: '201',
      wing: 'Wing B',
      mobile: '9876543216',
      email: 'vikram@example.com',
      isApprover: true,
    ),
    Resident(
      id: 'R004',
      name: 'Aman Gupta',
      flatNumber: '202',
      wing: 'Wing B',
      mobile: '9876543219',
      email: 'aman@example.com',
    ),
    Resident(
      id: 'R005',
      name: 'Priya Mehta',
      flatNumber: '301',
      wing: 'Wing C',
      mobile: '9876543213',
      email: 'priya@example.com',
    ),
    Resident(
      id: 'R006',
      name: 'Anil Kumar',
      flatNumber: '401',
      wing: 'Wing D',
      mobile: '9876543220',
      email: 'anil@example.com',
      isMaker: true,
    ),
  ];

  static List<Resident> getAllResidents() => List.unmodifiable(_residents);

  static void updateRoleFlags(String id, {bool? admin, bool? maker, bool? checker, bool? approver}) {
    final resident = _residents.firstWhere((r) => r.id == id);
    if (admin != null) resident.isAdmin = admin;
    if (maker != null) resident.isMaker = maker;
    if (checker != null) resident.isChecker = checker;
    if (approver != null) resident.isApprover = approver;
  }

  static void addResident(Resident resident) => _residents.add(resident);

  // Admin transfer audit log
  static final List<AdminTransferLog> _adminLogs = [];

  static List<AdminTransferLog> getAdminLogs() => List.unmodifiable(_adminLogs.reversed);

  static void logAdminTransfer({
    required String residentId,
    required String residentName,
    required bool granted, // true = granted, false = revoked
    required String reason,
    required String changedBy,
  }) {
    _adminLogs.add(AdminTransferLog(
      residentId: residentId,
      residentName: residentName,
      granted: granted,
      reason: reason,
      changedBy: changedBy,
      at: DateTime.now(),
    ));
  }

  // Dual role validation methods
  static String? getAdminWorkflowRole(String societyId) {
    final admin = _residents.where((r) => r.isAdmin).firstOrNull;
    if (admin == null) return null;
    
    if (admin.isMaker) return 'Maker';
    if (admin.isChecker) return 'Checker';
    if (admin.isApprover) return 'Approver';
    return null;
  }

  static bool canAssignRole(String residentId, String role, String societyId) {
    final resident = _residents.firstWhere((r) => r.id == residentId);
    final policy = MockSocietyRepository.getDualRolePolicy(societyId);
    
    // If policy is separateAdmin, admin cannot have any workflow roles
    if (policy == DualRolePolicy.separateAdmin && resident.isAdmin) {
      return false;
    }
    
    // If policy is adminPlusOne and resident is admin
    if (policy == DualRolePolicy.adminPlusOne && resident.isAdmin) {
      // Check if admin already has a workflow role
      final currentRole = getAdminWorkflowRole(societyId);
      if (currentRole != null && currentRole != role) {
        return false; // Admin already has a different workflow role
      }
    }
    
    // Check if role is already taken by admin (for adminPlusOne policy)
    if (policy == DualRolePolicy.adminPlusOne) {
      final adminRole = getAdminWorkflowRole(societyId);
      if (adminRole == role && !resident.isAdmin) {
        return false; // Role is already taken by admin
      }
    }
    
    return true;
  }

  static String? validateDualRoleAssignment(String residentId, String role, bool newValue, String societyId) {
    if (!newValue) return null; // Always allow revoking roles
    
    final resident = _residents.firstWhere((r) => r.id == residentId);
    final policy = MockSocietyRepository.getDualRolePolicy(societyId);
    
    if (policy == DualRolePolicy.separateAdmin && resident.isAdmin) {
      return 'Admin cannot hold workflow roles in Separate Admin policy';
    }
    
    if (policy == DualRolePolicy.adminPlusOne && resident.isAdmin) {
      final currentRole = getAdminWorkflowRole(societyId);
      if (currentRole != null && currentRole != role) {
        return 'Admin already has $currentRole role. Please revoke it first.';
      }
    }
    
    if (policy == DualRolePolicy.adminPlusOne && !resident.isAdmin) {
      final adminRole = getAdminWorkflowRole(societyId);
      if (adminRole == role) {
        return 'This role is already assigned to Admin';
      }
    }
    
    return null; // No validation error
  }

  static void updateRoleFlagsWithValidation(String id, {
    bool? admin, 
    bool? maker, 
    bool? checker, 
    bool? approver,
    required String societyId,
  }) {
    // Validate before updating
    if (maker != null && maker == true) {
      final error = validateDualRoleAssignment(id, 'Maker', true, societyId);
      if (error != null) throw Exception(error);
    }
    if (checker != null && checker == true) {
      final error = validateDualRoleAssignment(id, 'Checker', true, societyId);
      if (error != null) throw Exception(error);
    }
    if (approver != null && approver == true) {
      final error = validateDualRoleAssignment(id, 'Approver', true, societyId);
      if (error != null) throw Exception(error);
    }
    
    // Proceed with normal update
    updateRoleFlags(id, admin: admin, maker: maker, checker: checker, approver: approver);
  }
}

class AdminTransferLog {
  final String residentId;
  final String residentName;
  final bool granted;
  final String reason;
  final String changedBy;
  final DateTime at;

  AdminTransferLog({
    required this.residentId,
    required this.residentName,
    required this.granted,
    required this.reason,
    required this.changedBy,
    required this.at,
  });
}
