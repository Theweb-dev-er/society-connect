import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';

import '../../features/auth/presentation/screens/login_page.dart';
import '../../features/auth/presentation/screens/register_page.dart';
import '../../features/auth/presentation/screens/otp_verification_page.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/maintenance_screen.dart';
import '../../features/home/presentation/screens/visitor_verification_screen.dart';
import '../../features/home/presentation/screens/visitor_history_screen.dart';
import '../../features/home/presentation/screens/expected_visitors_screen.dart';
import '../../features/home/presentation/screens/recurring_visitors_screen.dart';
import '../../features/home/presentation/screens/complaints_screen.dart';
import '../../features/home/presentation/screens/notices_screen.dart';
import '../../features/home/presentation/screens/security_dashboard_screen.dart';
import '../../features/home/presentation/screens/security_new_entry_screen.dart';
import '../../features/home/presentation/screens/security_pre_approved_screen.dart';
import '../../features/home/presentation/screens/security_inside_screen.dart';
import '../../features/home/presentation/screens/security_gate_logs_screen.dart';
import '../../features/home/presentation/screens/secretary_dashboard_screen.dart';
import '../../features/home/presentation/screens/secretary_create_notice_screen.dart';
import '../../features/home/presentation/screens/secretary_manage_complaints_screen.dart';
import '../../features/home/presentation/screens/secretary_resident_directory_screen.dart';
import '../../features/home/presentation/screens/secretary_maintenance_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/profile_screen.dart';
import '../../features/services/presentation/screens/services_screen.dart';
import '../../features/home/presentation/screens/qr_scanner_screen.dart';
import '../../features/billing/presentation/screens/treasurer_dashboard_screen.dart';
import '../../features/billing/presentation/screens/president_dashboard_screen.dart';
import '../../features/billing/presentation/screens/pending_approvals_screen.dart';
import '../../features/billing/presentation/screens/approval_detail_screen.dart';
import '../../features/billing/presentation/screens/expense_entry_screen.dart';
import '../../features/billing/presentation/screens/audit_log_screen.dart';
import '../../features/auth/presentation/screens/manage_residents_screen.dart';
import '../../features/auth/presentation/screens/manage_security_guards_screen.dart';
import '../../features/subscription/presentation/screens/subscribe_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (state.matchedLocation == '/') {
        return AppRoutes.splash;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpVerificationPage(
            roleName: extra['roleName'] as String? ?? 'Resident',
            mobileNumber: extra['mobileNumber'] as String? ?? 'Unknown',
            isRegistration: extra['isRegistration'] as bool? ?? false,
            userName: extra['userName'] as String?,
            societyId: extra['societyId'] as String?,
            societyName: extra['societyName'] as String?,
            societyCode: extra['societyCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityDashboard,
        builder: (context, state) => const SecurityDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.complaints,
        builder: (context, state) => const ComplaintsScreen(),
      ),
      GoRoute(
        path: AppRoutes.visitors,
        builder: (context, state) => const VisitorVerificationScreen(),
      ),
      GoRoute(
        path: '/visitor-history',
        builder: (context, state) => const VisitorHistoryScreen(),
      ),
      GoRoute(
        path: '/expected-visitors',
        builder: (context, state) => const ExpectedVisitorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.recurringVisitors,
        builder: (context, state) => const RecurringVisitorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.maintenance,
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.notices,
        builder: (context, state) => const NoticesScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrScanner,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityNewEntry,
        builder: (context, state) => const SecurityNewEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityPreApproved,
        builder: (context, state) => const SecurityPreApprovedScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityInside,
        builder: (context, state) => const SecurityInsideScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityGateLogs,
        builder: (context, state) => const SecurityGateLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.secretaryDashboard,
        builder: (context, state) => const SecretaryDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.secretaryCreateNotice,
        builder: (context, state) => const SecretaryCreateNoticeScreen(),
      ),
      GoRoute(
        path: AppRoutes.secretaryManageComplaints,
        builder: (context, state) => const SecretaryManageComplaintsScreen(),
      ),
      GoRoute(
        path: AppRoutes.secretaryResidentDirectory,
        builder: (context, state) => const SecretaryResidentDirectoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.secretaryMaintenance,
        builder: (context, state) => const SecretaryMaintenanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.treasurerDashboard,
        builder: (context, state) => const TreasurerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.presidentDashboard,
        builder: (context, state) => const PresidentDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApprovals,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PendingApprovalsScreen(role: extra['role'] as String? ?? 'checker');
        },
      ),
      GoRoute(
        path: AppRoutes.approvalDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ApprovalDetailScreen(
            id: extra['id'] as String? ?? '',
            role: extra['role'] as String? ?? 'checker',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.expenseEntry,
        builder: (context, state) => const ExpenseEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.auditLog,
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageResidents,
        builder: (context, state) => const ManageResidentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageSecurityGuards,
        builder: (context, state) => const ManageSecurityGuardsScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscribe,
        builder: (context, state) => const SubscribeScreen(),
      ),
    ],
  );
});
