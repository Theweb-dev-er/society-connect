class CurrentUser {
  static String name = 'Rajesh Sharma';
  static String role = 'resident';
  static bool isOwner = false;
  static bool isAdmin = false;
  static bool isMaker = false;
  static bool isChecker = false;
  static bool isApprover = false;
  static bool isSecurityGuard = false;
  // Security Guard access flags
  static bool guardCanAddEntry = false;
  static bool guardCanManagePreApproved = false;
  static bool guardCanViewInsideList = false;
  static bool guardCanViewGateLogs = false;
  static String? guardId;
  static String? societyId;
  static String? societyName;
  static String? societyCode;
  static String? accessToken;
  static String? refreshToken;

  static void setUser({
    required String name,
    required String role,
    bool owner = false,
    bool admin = false,
    bool maker = false,
    bool checker = false,
    bool approver = false,
    bool securityGuard = false,
    bool guardCanAddEntry = false,
    bool guardCanManagePreApproved = false,
    bool guardCanViewInsideList = false,
    bool guardCanViewGateLogs = false,
    String? guardId,
    String? societyId,
    String? societyName,
    String? societyCode,
    String? accessToken,
    String? refreshToken,
  }) {
    CurrentUser.name = name;
    CurrentUser.role = role;
    isOwner = owner;
    isAdmin = admin;
    isMaker = maker;
    isChecker = checker;
    isApprover = approver;
    isSecurityGuard = securityGuard;
    CurrentUser.guardCanAddEntry = guardCanAddEntry;
    CurrentUser.guardCanManagePreApproved = guardCanManagePreApproved;
    CurrentUser.guardCanViewInsideList = guardCanViewInsideList;
    CurrentUser.guardCanViewGateLogs = guardCanViewGateLogs;
    CurrentUser.guardId = guardId;
    CurrentUser.societyId = societyId;
    CurrentUser.societyName = societyName;
    CurrentUser.societyCode = societyCode;
    CurrentUser.accessToken = accessToken;
    CurrentUser.refreshToken = refreshToken;
  }

  static void clear() {
    name = 'Guest';
    role = 'resident';
    isOwner = false;
    isAdmin = false;
    isMaker = false;
    isChecker = false;
    isApprover = false;
    isSecurityGuard = false;
    guardCanAddEntry = false;
    guardCanManagePreApproved = false;
    guardCanViewInsideList = false;
    guardCanViewGateLogs = false;
    guardId = null;
    societyId = null;
    societyName = null;
    societyCode = null;
    accessToken = null;
    refreshToken = null;
  }
}
