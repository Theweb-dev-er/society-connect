import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/visitor_service.dart';
import '../widgets/visitor_notification_dialog.dart';

class VisitorVerificationScreen extends StatefulWidget {
  final String? visitorId;

  const VisitorVerificationScreen({
    super.key,
    this.visitorId,
  });

  @override
  State<VisitorVerificationScreen> createState() => _VisitorVerificationScreenState();
}

class _VisitorVerificationScreenState extends State<VisitorVerificationScreen> {
  bool _isLoading = false;
  List<dynamic> _visitors = [];

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
    if (widget.visitorId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoOpenVisitorDialog(widget.visitorId!);
      });
    }
  }

  Future<void> _autoOpenVisitorDialog(String visitorId) async {
    try {
      final visitor = await VisitorService().getVisitor(visitorId);
      if (mounted) {
        VisitorNotificationDialog.show(
          context,
          visitor: visitor,
          onActionCompleted: _refreshVisitors,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load visitor details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchVisitors() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await VisitorService().listVisitors(status: 'expected');
      if (mounted) {
        setState(() {
          _visitors = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pending approvals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshVisitors() async {
    await _fetchVisitors();
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  IconData _getIconForType(String? type) {
    final t = type?.toLowerCase() ?? 'guest';
    if (t == 'delivery') {
      return Icons.local_shipping_outlined;
    } else if (t == 'service') {
      return Icons.build_outlined;
    }
    return Icons.face_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Visitor Verification',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),
          body: RefreshIndicator(
            onRefresh: _refreshVisitors,
            color: const Color(0xFF3B82F6),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridCard(
                          title: 'Visitor History',
                          subtitle: 'View past visitors',
                          icon: Icons.history,
                          iconColor: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFEFF6FF),
                          onTap: () => context.push('/visitor-history'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGridCard(
                          title: 'Expected Visitors',
                          subtitle: 'Pre-approve guests',
                          icon: Icons.person_add_alt_1_outlined,
                          iconColor: const Color(0xFF10B981),
                          bgColor: const Color(0xFFECFDF5),
                          onTap: () => context.push('/expected-visitors'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridCard(
                          title: 'Recurring Visitors',
                          subtitle: 'Manage regular access',
                          icon: Icons.people_alt_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFF3E8FF),
                          onTap: () => context.push('/recurring-visitors'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGridCard(
                          title: 'Emergency',
                          subtitle: 'Quick SOS access',
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFFEF4444),
                          bgColor: const Color(0xFFFEF2F2),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Pending Approvals Header
                  Row(
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_visitors.length}',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_isLoading && _visitors.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_visitors.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF10B981)),
                          SizedBox(height: 16),
                          Text(
                            'No Pending Approvals',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1F2937)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'All visitors have been checked in.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _visitors.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final visitor = _visitors[index];
                        return _buildPendingCard(
                          context: context,
                          visitor: visitor,
                        );
                      },
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
          borderRadius: BorderRadius.circular(16),
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
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard({
    required BuildContext context,
    required Map<String, dynamic> visitor,
  }) {
    final name = visitor['name'] ?? 'Unknown';
    final type = visitor['type']?.toString().toUpperCase() ?? 'GUEST';
    final time = _formatTime(visitor['created_at']);
    final icon = _getIconForType(visitor['type']);

    return GestureDetector(
      onTap: () => _showPendingApprovalDialog(context, visitor),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Color(0xFFF97316),
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF97316).withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFFF59E0B), size: 28),
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
                      const SizedBox(height: 4),
                      Text(
                        '$type • $time',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Waiting at Main Gate',
                          style: TextStyle(
                            color: Color(0xFFF97316),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
    );
  }

  void _showPendingApprovalDialog(
    BuildContext context,
    Map<String, dynamic> visitor,
  ) {
    VisitorNotificationDialog.show(
      context,
      visitor: visitor,
      onActionCompleted: _refreshVisitors,
    );
  }
}
