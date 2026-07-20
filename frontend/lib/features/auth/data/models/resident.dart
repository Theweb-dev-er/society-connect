class Resident {
  final String id;
  String name;
  String flatNumber;
  String wing;
  String mobile;
  String email;
  bool isOwner;
  bool isAdmin;
  bool isMaker;
  bool isChecker;
  bool isApprover;

  Resident({
    required this.id,
    required this.name,
    required this.flatNumber,
    required this.wing,
    required this.mobile,
    required this.email,
    this.isOwner = false,
    this.isAdmin = false,
    this.isMaker = false,
    this.isChecker = false,
    this.isApprover = false,
  });
}
