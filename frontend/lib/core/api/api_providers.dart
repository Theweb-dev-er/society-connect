import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audit_service.dart';
import 'auth_service.dart';
import 'billing_service.dart';
import 'guard_service.dart';
import 'resident_service.dart';
import 'visitor_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final visitorServiceProvider = Provider<VisitorService>((ref) {
  return VisitorService();
});

final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService();
});

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService();
});

final guardServiceProvider = Provider<GuardService>((ref) {
  return GuardService();
});

final residentServiceProvider = Provider<ResidentService>((ref) {
  return ResidentService();
});
