import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_providers.dart';

class ApprovalDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final String role; // 'checker' or 'approver'

  const ApprovalDetailScreen({super.key, required this.id, required this.role});

  @override
  ConsumerState<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends ConsumerState<ApprovalDetailScreen> {
  dynamic _item;
  bool _isLoading = true;
  String? _error;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItem();
  }

  Future<void> _fetchItem() async {
    try {
      final service = ref.read(billingServiceProvider);
      final data = await service.listWorkflowItems();
      final found = data.firstWhere(
        (i) => i['id'] == widget.id,
        orElse: () => null,
      );
      setState(() {
        _item = found;
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
    _commentController.dispose();
    super.dispose();
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'draft': return const Color(0xFF9CA3AF);
      case 'pending_checker': return const Color(0xFFF59E0B);
      case 'pending_approver': return const Color(0xFF3B82F6);
      case 'approved': return const Color(0xFF10B981);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFF9CA3AF);
    }
  }

  Color _stageBg(String stage) {
    switch (stage) {
      case 'draft': return const Color(0xFFF3F4F6);
      case 'pending_checker': return const Color(0xFFFFFBEB);
      case 'pending_approver': return const Color(0xFFDBEAFE);
      case 'approved': return const Color(0xFFECFDF5);
      case 'rejected': return const Color(0xFFFEF2F2);
      default: return const Color(0xFFF3F4F6);
    }
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'draft': return 'Draft';
      case 'pending_checker': return 'Pending Review';
      case 'pending_approver': return 'Pending Approval';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      default: return stage;
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.block, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send Back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        Text('Return to Secretary with feedback', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Reason / Comments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for rejection...',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleReject();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Send Back', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleApprove() async {
    try {
      final service = ref.read(billingServiceProvider);
      final action = widget.role == 'checker' ? 'check' : 'approve';
      await service.performAction(widget.id, action: action);
      await _fetchItem();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.role == 'checker' ? 'Forwarded to President for approval' : 'Approved and published'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleReject() async {
    try {
      final service = ref.read(billingServiceProvider);
      await service.performAction(
        widget.id,
        action: 'reject',
        comment: _commentController.text.isEmpty ? 'Sent back for revision' : _commentController.text,
      );
      await _fetchItem();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sent back to Secretary for revision'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval Detail')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
              const SizedBox(height: 12),
              Text('Error: $_error', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchItem, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval Detail')),
        body: const Center(child: Text('Item not found')),
      );
    }

    final item = _item;
    final isBill = item['type'] == 'bill';
    final stage = item['stage'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Approval Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _stageBg(stage),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _stageColor(stage).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _stageColor(stage)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Status: ${_stageLabel(stage)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _stageColor(stage)),
                              ),
                              if (item['rejection_reason'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Reason: ${item['rejection_reason']}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Amount
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isBill ? const Color(0xFFDBEAFE) : const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isBill ? Icons.receipt_long : Icons.payments,
                                size: 18,
                                color: isBill ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isBill ? 'Maintenance Bill' : 'Society Expense',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Rs.${(item['amount'] as num).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Submitted by', (item['submitted_by']?['name'] ?? 'Unknown') as String),
                        _buildDetailRow('Submitted on', _formatDate(item['submitted_at'] as String?)),
                        if (isBill) ...[
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _buildBillDetails(item['payload'] ?? {}),
                        ] else ...[
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _buildExpenseDetails(item['payload'] ?? {}),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Timeline
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Activity Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        const SizedBox(height: 16),
                        _buildTimelineItem(
                          action: 'Submitted',
                          actor: (item['submitted_by']?['name'] ?? 'Unknown') as String,
                          role: 'Maker',
                          timestamp: item['submitted_at'] as String?,
                        ),
                        if (item['checked_by'] != null)
                          _buildTimelineItem(
                            action: 'Checked & Forwarded',
                            actor: (item['checked_by']['name'] ?? 'Unknown') as String,
                            role: 'Checker',
                            comment: item['checker_comment'] as String?,
                            timestamp: item['checked_at'] as String?,
                          ),
                        if (item['approved_by'] != null)
                          _buildTimelineItem(
                            action: 'Approved',
                            actor: (item['approved_by']['name'] ?? 'Unknown') as String,
                            role: 'Approver',
                            comment: item['approver_comment'] as String?,
                            timestamp: item['approved_at'] as String?,
                          ),
                        if (item['rejected_by'] != null)
                          _buildTimelineItem(
                            action: 'Rejected',
                            actor: (item['rejected_by']['name'] ?? 'Unknown') as String,
                            role: 'Approver',
                            comment: item['rejection_reason'] as String?,
                            timestamp: item['rejected_at'] as String?,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          if (stage != 'approved' && stage != 'rejected')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showRejectDialog,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Send Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _handleApprove,
                        icon: Icon(widget.role == 'checker' ? Icons.arrow_forward : Icons.check, size: 18),
                        label: Text(widget.role == 'checker' ? 'Forward' : 'Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetails(Map<String, dynamic> payload) {
    final entries = (payload['entries'] as List? ?? []).cast<Map<String, dynamic>>();
    final billPeriod = payload['bill_period'] as Map<String, dynamic>?;
    final month = billPeriod?['month'] ?? payload['month'];
    final year = billPeriod?['year'] ?? payload['year'];
    final residentCount = payload['resident_count'] ?? payload['residentCount'];
    final totalAmount = payload['total_amount'] ?? payload['totalAmount'];
    final categories = (payload['categories'] as List? ?? []).cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Billing Month', '$month $year'),
        _buildDetailRow('Total Residents', '$residentCount'),
        _buildDetailRow('Total Amount', 'Rs.${totalAmount}'),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Category Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          ...categories.map((cat) {
            final catRates = (cat['rates'] as Map<String, dynamic>?) ?? {};
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat['category_name'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    children: catRates.entries.map((e) => Text('${e.key}: Rs.${e.value}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        const Text('Sample Entries', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        ...entries.take(3).map((e) {
          final categoryAmounts = e['categoryAmounts'] as Map<String, dynamic>?;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
                      child: Text(e['flat'] as String? ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e['residentName'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
                    Text('Rs.${e['total'] ?? e['amount']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                  ],
                ),
                if (categoryAmounts != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: categoryAmounts.entries.map((c) => Text('${c.key}: Rs.${c.value}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExpenseDetails(Map<String, dynamic> payload) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Category', payload['category'] ?? '-'),
        _buildDetailRow('Vendor', payload['vendorName'] ?? '-'),
        _buildDetailRow('Description', payload['description'] ?? '-'),
        _buildDetailRow('Date', payload['expenseDate']?.toString().split('T').first ?? '-'),
        if (payload['receiptUrl'] != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(payload['receiptUrl'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate.substring(0, 10);
    }
  }

  String _formatTimestamp(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildTimelineItem({
    required String action,
    required String actor,
    required String role,
    String? comment,
    String? timestamp,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(width: 2, height: 40, color: const Color(0xFFE2E8F0)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$actor ($role)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"$comment"',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
                if (timestamp != null && timestamp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
