import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VisitorVerificationScreen extends StatefulWidget {
  const VisitorVerificationScreen({super.key});

  @override
  State<VisitorVerificationScreen> createState() => _VisitorVerificationScreenState();
}

class _VisitorVerificationScreenState extends State<VisitorVerificationScreen> {
  bool _isLoading = false;

  Future<void> _refreshVisitors() async {
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
                        child: const Text(
                          '2',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pending Approval Cards
                  _buildPendingCard(
                    context: context,
                    name: 'Rajesh Kumar',
                    type: 'Delivery',
                    time: '3:45 PM',
                    status: 'Waiting at Main Gate',
                    icon: Icons.face,
                  ),
                  const SizedBox(height: 16),
                  _buildPendingCard(
                    context: context,
                    name: 'Priya Sharma',
                    type: 'Guest',
                    time: '3:50 PM',
                    status: 'Waiting at Main Gate',
                    icon: Icons.face_3,
                    guestCount: 3,
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
    ));
  }

  Widget _buildPendingCard({
    required BuildContext context,
    required String name,
    required String type,
    required String time,
    required String status,
    required IconData icon,
    int? guestCount,
  }) {
    return GestureDetector(
      onTap: () => _showPendingApprovalDialog(
        context,
        name: name,
        type: type,
        time: time,
        icon: icon,
        guestCount: guestCount,
      ),
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
                      guestCount != null && guestCount > 1 ? '$name + ${guestCount - 1} others' : name,
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
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ], // Column.children
                ), // Column
              ), // Expanded
            ], // Row.children
          ), // Row
        ), // Container (inner)
      ), // ClipRRect
      ), // Container (outer)
    ); // GestureDetector
  }

  void _showPendingApprovalDialog(
    BuildContext context, {
    required String name,
    required String type,
    required String time,
    required IconData icon,
    int? guestCount,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Visitor at Gate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, size: 40, color: const Color(0xFFF59E0B)),
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  guestCount != null && guestCount > 1 ? '$name + ${guestCount - 1}' : name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      color: Color(0xFFF97316),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Details List
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 20, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Requested At',
                            style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                          ),
                          Text(
                            time,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gate Location',
                            style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                          ),
                          Text(
                            'Main Gate',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Allow Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Allow Entry',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Deny',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call_outlined, size: 16, color: Color(0xFF3B82F6)),
                            SizedBox(width: 8),
                            Text(
                              'Call Security',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
