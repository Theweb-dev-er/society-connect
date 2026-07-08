import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_providers.dart';

// Note: Mock repository imports removed — now using real API

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _filterRole = 'All';
  String _filterAction = 'All';
  final _searchController = TextEditingController();
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _roleFilters = [
    'All',
    'Admin',
    'Secretary',
    'Treasurer',
    'President',
    'Maker',
    'Checker',
    'Approver',
    'Checker & Approver',
    'Resident',
  ];
  final List<String> _actionFilters = [
    'All',
    'Created',
    'Submitted',
    'Checked & Forwarded',
    'Approved',
    'Rejected',
    'Updated',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final service = ref.read(auditServiceProvider);
      final data = await service.listAuditLogs(
        role: _filterRole == 'All' ? null : _filterRole,
        action: _filterAction == 'All' ? null : _filterAction,
      );
      setState(() {
        _logs = data;
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
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _logs.where((log) {
      final nameMatch = query.isEmpty ||
          ((log['actor_name'] ?? '') as String).toLowerCase().contains(query) ||
          ((log['target_item'] ?? '') as String).toLowerCase().contains(query);
      return nameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Audit Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Color(0xFF3B82F6)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report export would download here'),
                  backgroundColor: Color(0xFF3B82F6),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by person or item name...',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Color(0xFF9CA3AF)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    const Text('Filters:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _filterRole,
                        items: _roleFilters,
                        onChanged: (v) {
                          setState(() => _filterRole = v!);
                          _fetchLogs();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _filterAction,
                        items: _actionFilters,
                        onChanged: (v) {
                          setState(() => _filterAction = v!);
                          _fetchLogs();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Summary Stats
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                _buildCountPill('Total', '${_filtered.length}', const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildCountPill('Bills', '${_filtered.where((l) => (l['target_item'] ?? '').toString().contains('Bill')).length}', const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildCountPill('Expenses', '${_filtered.where((l) => !(l['target_item'] ?? '').toString().contains('Bill')).length}', const Color(0xFFF59E0B)),
              ],
            ),
          ),

          // Log List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
                            const SizedBox(height: 12),
                            Text('Error: $_error', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchLogs, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) => _buildLogCard(_filtered[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCountPill(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          const SizedBox(width: 4),
          Text(count, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLogCard(dynamic log) {
    final action = (log['action'] ?? '') as String;
    final targetItem = (log['target_item'] ?? '') as String;
    final actorRole = (log['actor_role'] ?? '') as String;
    final actorName = (log['actor_name'] ?? 'Unknown') as String;
    final comment = log['comment'] as String?;
    final timestamp = log['timestamp'] as String?;

    final actionColor = _getActionColor(action);
    final actionIcon = _getActionIcon(action);

    String dateStr = '';
    if (timestamp != null && timestamp.isNotEmpty) {
      try {
        final dt = DateTime.parse(timestamp);
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        dateStr = timestamp.substring(0, 10);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(actionIcon, size: 18, color: actionColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        action,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: actionColor),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  targetItem,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        actorRole,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      actorName,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('Approved')) return const Color(0xFF10B981);
    if (action.contains('Rejected')) return const Color(0xFFEF4444);
    if (action.contains('Checked')) return const Color(0xFF3B82F6);
    if (action.contains('Submitted')) return const Color(0xFF8B5CF6);
    if (action.contains('Created')) return const Color(0xFF06B6D4);
    return const Color(0xFF64748B);
  }

  IconData _getActionIcon(String action) {
    if (action.contains('Approved')) return Icons.check_circle;
    if (action.contains('Rejected')) return Icons.block;
    if (action.contains('Checked')) return Icons.arrow_forward;
    if (action.contains('Submitted')) return Icons.send;
    if (action.contains('Created')) return Icons.add_circle_outline;
    return Icons.info_outline;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.search_off_outlined, size: 40, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 20),
            const Text('No matching records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            const Text('Try adjusting the filters above.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}
