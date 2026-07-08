import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/models/workflow_models.dart';
import '../../data/repository/mock_workflow_repository.dart';

class PresidentDashboardScreen extends StatefulWidget {
  const PresidentDashboardScreen({super.key});

  @override
  State<PresidentDashboardScreen> createState() => _PresidentDashboardScreenState();
}

class _PresidentDashboardScreenState extends State<PresidentDashboardScreen> {
  bool _isLoading = false;

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pendingApprover = MockWorkflowRepository.getPendingApprover();
    final approvedThisMonth = MockWorkflowRepository.getByStage(WorkflowStage.approved)
        .where((i) => i.timeline.last.at.month == DateTime.now().month)
        .fold<double>(0, (sum, i) => sum + i.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'President Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined, color: Color(0xFF3B82F6)),
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
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
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
                          child: const Icon(Icons.gavel_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello, President', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                              Text('Vikram Rao', style: TextStyle(fontSize: 13, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Approved This Month', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      'Rs.${approvedThisMonth.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pending_actions,
                      iconColor: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFFBEB),
                      value: '${pendingApprover.length}',
                      label: 'Pending Approval',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      value: '2',
                      label: 'Approved Today',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.account_balance_wallet,
                      iconColor: const Color(0xFF8B5CF6),
                      bgColor: const Color(0xFFFAF5FF),
                      value: '45L',
                      label: 'Society Balance',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pending Final Approval
              _buildSectionHeader('Pending Final Approval', 'View All', () {
                context.push(AppRoutes.pendingApprovals, extra: {'role': 'approver'});
              }),
              const SizedBox(height: 12),
              if (pendingApprover.isEmpty)
                _buildEmptyState('No items pending approval', 'All clear!')
              else
                ...pendingApprover.take(3).map((item) => _buildPendingCard(item)),

              const SizedBox(height: 20),

              // Monthly Overview
              _buildSectionHeader('This Month Overview', '', () {}),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildOverviewRow('Bills Generated', 'Rs.3,15,000', const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _buildOverviewRow('Expenses Approved', 'Rs.1,25,000', const Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    _buildOverviewRow('Collections', 'Rs.2,45,000', const Color(0xFF10B981)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                    _buildOverviewRow('Net Position', '+Rs.1,20,000', const Color(0xFF059669)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        if (action.isNotEmpty)
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
      onTap: () => context.push(AppRoutes.approvalDetail, extra: {'id': item.id, 'role': 'approver'}),
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
                color: isBill ? const Color(0xFFDBEAFE) : const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isBill ? Icons.receipt_long : Icons.payments, size: 20, color: isBill ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text('Checked by Sunita Patel', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Ready', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
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
