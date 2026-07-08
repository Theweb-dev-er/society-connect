import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecretaryManageComplaintsScreen extends StatefulWidget {
  const SecretaryManageComplaintsScreen({super.key});

  @override
  State<SecretaryManageComplaintsScreen> createState() => _SecretaryManageComplaintsScreenState();
}

class _SecretaryManageComplaintsScreenState extends State<SecretaryManageComplaintsScreen> {
  final List<Map<String, dynamic>> _complaints = [
    {
      'id': 'CMP1024',
      'title': 'Plumbing Issue',
      'description': 'Leaking tap in the kitchen.',
      'resident': 'Amit Kumar (Block A-402)',
      'date': 'June 24, 2026',
      'status': 'Open',
    },
    {
      'id': 'CMP1018',
      'title': 'Elevator Not Working',
      'description': 'Block A elevator is stuck on the 3rd floor.',
      'resident': 'Secretary Raj (System)',
      'date': 'June 20, 2026',
      'status': 'In Progress',
    },
    {
      'id': 'CMP0992',
      'title': 'Street Light Broken',
      'description': 'The street light near the main gate is flickering.',
      'resident': 'Neha Sharma (Block B-105)',
      'date': 'June 15, 2026',
      'status': 'Resolved',
    },
  ];

  void _updateStatus(int index, String status) {
    setState(() {
      _complaints[index]['status'] = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to $status'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
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
              'Manage Complaints',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _complaints.length,
            itemBuilder: (context, index) {
              final complaint = _complaints[index];
              return _buildComplaintCard(index, complaint);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(int index, Map<String, dynamic> complaint) {
    final status = complaint['status'] as String;
    Color getStatusColor() {
      if (status == 'Resolved') return const Color(0xFF10B981);
      if (status == 'In Progress') return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    }

    Color getStatusBgColor() {
      if (status == 'Resolved') return const Color(0xFFECFDF5);
      if (status == 'In Progress') return const Color(0xFFFFFBEB);
      return const Color(0xFFFEF2F2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${complaint['id']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusBgColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: getStatusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            complaint['title'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            complaint['description'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                complaint['resident'] as String,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Text(
                    complaint['date'] as String,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              if (status != 'Resolved')
                Row(
                  children: [
                    if (status == 'Open')
                      TextButton(
                        onPressed: () => _updateStatus(index, 'In Progress'),
                        child: const Text('In Progress', style: TextStyle(color: Color(0xFFF59E0B))),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _updateStatus(index, 'Resolved'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                      ),
                      child: const Text('Resolve'),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
