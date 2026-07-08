import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/models/workflow_models.dart';
import '../../data/repository/mock_workflow_repository.dart';

class TreasurerDashboardScreen extends StatefulWidget {
  const TreasurerDashboardScreen({super.key});

  @override
  State<TreasurerDashboardScreen> createState() => _TreasurerDashboardScreenState();
}

class _TreasurerDashboardScreenState extends State<TreasurerDashboardScreen> {
  bool _isLoading = false;

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pendingChecker = MockWorkflowRepository.getPendingChecker();
    final totalPendingAmount = pendingChecker.fold<double>(0, (sum, i) => sum + i.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Treasurer Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, color: Color(0xFF3B82F6)),
            onPressed: () => context.push(AppRoutes.auditLog),
            tooltip: 'Audit Log',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, Treasurer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Sunita Patel',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pending Review Amount',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs.${_formatAmount(totalPendingAmount)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pending_actions,
                      iconColor: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFFBEB),
                      value: '${pendingChecker.length}',
                      label: 'Pending Review',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      value: '3',
                      label: 'Checked Today',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pending Approvals Card
              _buildSectionHeader('Pending Review', 'View All', () {
                context.push(AppRoutes.pendingApprovals, extra: {'role': 'checker'});
              }),
              const SizedBox(height: 12),
              if (pendingChecker.isEmpty)
                _buildEmptyState('No items pending review', 'All caught up!')
              else
                ...pendingChecker.take(3).map((item) => _buildPendingCard(item)),

              const SizedBox(height: 20),

              // Recent Activity
              _buildSectionHeader('Recent Activity', 'View All', () {
                context.push(AppRoutes.auditLog);
              }),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.check_circle,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                title: 'Security Agency Payment forwarded',
                subtitle: 'To President for approval',
                time: 'Today, 10:00 AM',
              ),
              const SizedBox(height: 10),
              _buildActivityItem(
                icon: Icons.receipt_long,
                iconColor: const Color(0xFF3B82F6),
                bgColor: const Color(0xFFEFF6FF),
                title: 'July 2026 Bills submitted',
                subtitle: 'From Secretary, awaiting review',
                time: 'Yesterday, 10:30 AM',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        GestureDetector(
          onTap: onTap,
          child: const Text('View All', style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildPendingCard(WorkflowItem item) {
    final isBill = item.type == OperationType.bill;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.approvalDetail, extra: {'id': item.id, 'role': 'checker'}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBill ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isBill ? Icons.receipt_long : Icons.payments, size: 20, color: isBill ? const Color(0xFFD97706) : const Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted by ${item.submittedBy}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs.${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, size: 32, color: Color(0xFF22C55E)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
