import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/router/app_routes.dart';
import '../../../auth/data/models/current_user.dart';
import '../../../billing/data/models/workflow_models.dart';
import '../../../billing/data/repository/mock_workflow_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;

  Future<void> _refreshDashboard() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: RefreshIndicator(
            onRefresh: _refreshDashboard,
            color: const Color(0xFF3B82F6),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrentUser.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    CurrentUser.role.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.push(AppRoutes.profile),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: () => context.go(AppRoutes.login),
                                  icon: const Icon(Icons.logout, color: Colors.white70),
                                  tooltip: 'Logout',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Society',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrentUser.societyName ?? 'Your Society',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // New Bill Alert Banner
                  Container(
                    margin: const EdgeInsets.only(left: 24, right: 24, top: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long, color: Color(0xFFEF4444), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'New Bill Generated',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'July 2026 maintenance is due on 15th July.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF991B1B).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.maintenance),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  
                  // Society Account Balance (visible to Admin, Maker, Checker, Approver)
                  if (CurrentUser.isAdmin || CurrentUser.isMaker || CurrentUser.isChecker || CurrentUser.isApprover)
                    _buildSocietyBalanceCard(),

                  // Workflow Permissions Section (for residents with flags)
                  if (CurrentUser.isAdmin || CurrentUser.isMaker || CurrentUser.isChecker || CurrentUser.isApprover)
                    _buildWorkflowSection(),

                  // Grid Items & Visitor Card
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridCard(
                                title: 'Notices',
                                icon: Icons.notifications_none_outlined,
                                iconColor: const Color(0xFFF97316),
                                bgColor: const Color(0xFFFFF7ED),
                                onTap: () => context.push(AppRoutes.notices),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildGridCard(
                                title: 'Complaints',
                                icon: Icons.chat_bubble_outline,
                                iconColor: const Color(0xFFEF4444),
                                bgColor: const Color(0xFFFEF2F2),
                                onTap: () => context.push(AppRoutes.complaints),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridCard(
                                title: 'Maintenance',
                                icon: Icons.currency_rupee,
                                iconColor: const Color(0xFF06B6D4),
                                bgColor: const Color(0xFFECFEFF),
                                onTap: () => context.push(AppRoutes.maintenance),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildGridCard(
                                title: 'Services',
                                icon: Icons.cleaning_services_outlined,
                                iconColor: const Color(0xFF3B82F6),
                                bgColor: const Color(0xFFEFF6FF),
                                onTap: () => context.push(AppRoutes.services),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Visitor Verification Card
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.visitors),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF5FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.how_to_reg, 
                                      color: Color(0xFFA855F7),
                                      size: 28,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          '2',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Visitor Verification',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Approve or deny visitor entry',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      color: Color(0xFFF97316),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '2 pending approvals',
                                      style: TextStyle(
                                        color: Color(0xFFF97316),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildWorkflowSection() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Workflow Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                child: const Text('Privileged', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (CurrentUser.isMaker) ...[
            _buildWorkflowAction(
              icon: Icons.add_card,
              iconColor: const Color(0xFF8B5CF6),
              bgColor: const Color(0xFFFAF5FF),
              title: 'Add Expense Entry',
              subtitle: 'Log new society expenses',
              onTap: () => context.push(AppRoutes.expenseEntry),
            ),
            const SizedBox(height: 10),
            _buildWorkflowAction(
              icon: Icons.receipt_long,
              iconColor: const Color(0xFF3B82F6),
              bgColor: const Color(0xFFEFF6FF),
              title: 'Generate Monthly Bills',
              subtitle: 'Create and submit bills for review',
              onTap: () => context.push('/bill-generation'),
            ),
            const SizedBox(height: 10),
          ],
          if (CurrentUser.isAdmin || CurrentUser.isMaker || CurrentUser.isChecker || CurrentUser.isApprover) ...[
            _buildWorkflowAction(
              icon: Icons.receipt_outlined,
              iconColor: const Color(0xFF06B6D4),
              bgColor: const Color(0xFFECFEFF),
              title: 'View Bills',
              subtitle: 'All generated bills with status',
              onTap: () => context.push(AppRoutes.bills),
            ),
            const SizedBox(height: 10),
          ],
          if (CurrentUser.isChecker) ...[
            _buildWorkflowAction(
              icon: Icons.fact_check,
              iconColor: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFFBEB),
              title: 'Pending Review',
              subtitle: 'Review bills and expenses from makers',
              badge: MockWorkflowRepository.getPendingChecker().length.toString(),
              onTap: () => context.push(AppRoutes.pendingApprovals, extra: {'role': 'checker'}),
            ),
            const SizedBox(height: 10),
          ],
          if (CurrentUser.isApprover) ...[
            _buildWorkflowAction(
              icon: Icons.gavel,
              iconColor: const Color(0xFF8B5CF6),
              bgColor: const Color(0xFFEDE9FE),
              title: 'Pending Approval',
              subtitle: 'Final approval for checked items',
              badge: MockWorkflowRepository.getPendingApprover().length.toString(),
              onTap: () => context.push(AppRoutes.pendingApprovals, extra: {'role': 'approver'}),
            ),
            const SizedBox(height: 10),
          ],
          if (CurrentUser.isAdmin) ...[
            _buildWorkflowAction(
              icon: Icons.admin_panel_settings_outlined,
              iconColor: const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
              title: 'Manage Residents',
              subtitle: 'Admin: assign Maker / Checker / Approver',
              onTap: () => context.push(AppRoutes.manageResidents),
            ),
            const SizedBox(height: 10),
            _buildWorkflowAction(
              icon: Icons.security,
              iconColor: const Color(0xFF22C55E),
              bgColor: const Color(0xFFDCFCE7),
              title: 'Manage Security Guards',
              subtitle: 'Create guards and restrict their access',
              onTap: () => context.push(AppRoutes.manageSecurityGuards),
            ),
            const SizedBox(height: 10),
            _buildWorkflowAction(
              icon: Icons.history,
              iconColor: const Color(0xFFA855F7),
              bgColor: const Color(0xFFFAF5FF),
              title: 'Gate Logs',
              subtitle: 'View all gate entry/exit history',
              onTap: () => context.push(AppRoutes.securityGateLogs),
            ),
            const SizedBox(height: 10),
          ],
          _buildWorkflowAction(
            icon: Icons.history,
            iconColor: const Color(0xFF64748B),
            bgColor: const Color(0xFFF1F5F9),
            title: 'Audit Log',
            subtitle: 'View complete approval history',
            onTap: () => context.push(AppRoutes.auditLog),
          ),
        ],
      ),
    );
  }

  Widget _buildSocietyBalanceCard() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Society Account Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '₹ 45,00,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last updated: today',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowAction({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor)),
              )
            else
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

