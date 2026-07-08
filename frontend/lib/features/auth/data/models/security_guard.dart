class SecurityGuard {
  final String id;
  String name;
  String mobile;
  String email;
  String gate;
  String shift;
  bool isActive;
  bool canAddEntry;
  bool canManagePreApproved;
  bool canViewInsideList;
  bool canViewGateLogs;

  SecurityGuard({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    this.gate = 'Gate 1',
    this.shift = 'Morning',
    this.isActive = true,
    this.canAddEntry = true,
    this.canManagePreApproved = true,
    this.canViewInsideList = true,
    this.canViewGateLogs = true,
  });
}
