import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/router/app_routes.dart';
import '../../../auth/data/models/current_user.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
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
            color: const Color(0xFF22C55E),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
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
                                  'Gate 1 / Shift A',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrentUser.name.isNotEmpty ? CurrentUser.name : 'Security Officer',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
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
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: () => context.go('/login'),
                                  icon: const Icon(Icons.logout, color: Colors.white70),
                                  tooltip: 'Logout',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Access restricted tiles based on admin permissions
                        if (!CurrentUser.guardCanAddEntry && !CurrentUser.guardCanManagePreApproved &&
                            !CurrentUser.guardCanViewInsideList && !CurrentUser.guardCanViewGateLogs)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_outline, color: Color(0xFFEF4444), size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'All access restricted. Contact Admin to enable features.',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            if (CurrentUser.guardCanAddEntry)
                              Expanded(
                                child: _buildGridCard(
                                  title: 'New Entry',
                                  subtitle: 'Log a visitor',
                                  icon: Icons.person_add_alt_1,
                                  iconColor: const Color(0xFF3B82F6),
                                  bgColor: const Color(0xFFEFF6FF),
                                  onTap: () => context.push('/security-new-entry'),
                                ),
                              )
                            else
                              Expanded(child: _buildLockedCard('New Entry')),
                            const SizedBox(width: 16),
                            if (CurrentUser.guardCanAddEntry)
                              Expanded(
                                child: _buildGridCard(
                                  title: 'Waiting at Gate',
                                  subtitle: 'Pending approval',
                                  icon: Icons.pending_actions_outlined,
                                  iconColor: const Color(0xFFEAB308),
                                  bgColor: const Color(0xFFFEF9C3),
                                  onTap: () => context.push('/security-waiting'),
                                ),
                              )
                            else
                              Expanded(child: _buildLockedCard('Waiting at Gate')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (CurrentUser.guardCanManagePreApproved)
                              Expanded(
                                child: _buildGridCard(
                                  title: 'Pre-Approved',
                                  subtitle: 'Expected today',
                                  icon: Icons.verified_user_outlined,
                                  iconColor: const Color(0xFF10B981),
                                  bgColor: const Color(0xFFECFDF5),
                                  onTap: () => context.push('/security-pre-approved'),
                                ),
                              )
                            else
                              Expanded(child: _buildLockedCard('Pre-Approved')),
                            const SizedBox(width: 16),
                            if (CurrentUser.guardCanViewInsideList)
                              Expanded(
                                child: _buildGridCard(
                                  title: 'Inside',
                                  subtitle: 'Current visitors',
                                  icon: Icons.meeting_room_outlined,
                                  iconColor: const Color(0xFFF97316),
                                  bgColor: const Color(0xFFFFF7ED),
                                  onTap: () => context.push('/security-inside'),
                                ),
                              )
                            else
                              Expanded(child: _buildLockedCard('Inside')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (CurrentUser.guardCanViewGateLogs)
                              Expanded(
                                child: _buildGridCard(
                                  title: 'Gate Logs',
                                  subtitle: 'Daily history of entries and exits',
                                  icon: Icons.history,
                                  iconColor: const Color(0xFFA855F7),
                                  bgColor: const Color(0xFFFAF5FF),
                                  onTap: () => context.push('/security-gate-logs'),
                                ),
                              )
                            else
                              Expanded(child: _buildLockedCard('Gate Logs')),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildActivityLog(
                          name: 'Amazon Delivery',
                          action: 'Entered • Flat 402',
                          time: 'Just now',
                          isEntry: true,
                        ),
                        const SizedBox(height: 12),
                        _buildActivityLog(
                          name: 'Rajesh (Plumber)',
                          action: 'Exited',
                          time: '10 mins ago',
                          isEntry: false,
                        ),
                        const SizedBox(height: 12),
                        _buildActivityLog(
                          name: 'Rohan Mehta (Guest)',
                          action: 'Entered • Flat 105',
                          time: '1 hr ago',
                          isEntry: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.qrScanner),
            backgroundColor: const Color(0xFF22C55E),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF), size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          const Text('Restricted', style: TextStyle(fontSize: 11, color: Color(0xFFD1D5DB))),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
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
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog({
    required String name,
    required String action,
    required String time,
    required bool isEntry,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEntry ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEntry ? Icons.arrow_downward : Icons.arrow_upward,
              color: isEntry ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
