import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/router/app_routes.dart';

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  final String role; // 'checker' or 'approver'

  const PendingApprovalsScreen({super.key, required this.role});

  @override
  ConsumerState<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends ConsumerState<PendingApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final service = ref.read(billingServiceProvider);
      final stage = widget.role == 'checker' ? 'pending_checker' : 'pending_approver';
      final data = await service.listWorkflowItems(stage: stage);
      setState(() {
        _items = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApprover = widget.role == 'approver';
    final pageTitle = isApprover ? 'Pending Approval' : 'Pending Review';
    final subtitle = isApprover
        ? 'Items forwarded by Treasurer awaiting final approval'
        : 'Bills & expenses submitted by Secretary';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(pageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF3B82F6),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Bills'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('bill', subtitle),
          _buildList('expense', subtitle),
        ],
      ),
    );
  }

  List<dynamic> _filterByType(String type) {
    return _items.where((i) => (i['type'] as String) == type).toList();
  }

  Widget _buildList(String type, String subtitle) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
            const SizedBox(height: 12),
            Text('Error: $_error', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchItems, child: const Text('Retry')),
          ],
        ),
      );
    }

    final items = _filterByType(type);

    if (items.isEmpty) {
      return _buildEmptyState(type == 'bill' ? 'No bills pending' : 'No expenses pending');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  Widget _buildItemCard(dynamic item) {
    final isBill = item['type'] == 'bill';
    final stageLabel = widget.role == 'checker' ? 'Pending Review' : 'Ready for Approval';
    final stageColor = widget.role == 'checker' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
    final stageBg = widget.role == 'checker' ? const Color(0xFFFFFBEB) : const Color(0xFFDBEAFE);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.approvalDetail, extra: {'id': item['id'] as String, 'role': widget.role}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: stageBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isBill ? Icons.receipt_long_outlined : Icons.payments_outlined,
                    size: 18,
                    color: stageColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBill ? 'Maintenance Bill' : 'Society Expense',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stageColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stageLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: stageColor),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetaItem(Icons.person_outline, 'By ${(item['submitted_by']?['name'] ?? 'Unknown')}'),
                      ),
                      Expanded(
                        child: _buildMetaItem(Icons.calendar_today_outlined, _formatDate(item['submitted_at'] as String?)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Amount', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          const SizedBox(height: 2),
                          Text(
                            'Rs.${_parseAmount(item['amount']).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                        ],
                      ),
                      FilledButton(
                        onPressed: () => context.push(
                          AppRoutes.approvalDetail,
                          extra: {'id': item['id'] as String, 'role': widget.role},
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text(
                          widget.role == 'checker' ? 'Review' : 'Approve',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoDate);
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return isoDate.substring(0, 10);
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            const Text('Check back later for new submissions.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}
