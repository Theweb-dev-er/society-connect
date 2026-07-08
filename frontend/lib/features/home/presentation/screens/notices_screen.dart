import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/widgets/common_states.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  bool _isLoading = false;

  Future<void> _refreshNotices() async {
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
              'Notice Board',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),
          body: RefreshIndicator(
            onRefresh: _refreshNotices,
            color: const Color(0xFF3B82F6),
            child: _isLoading 
              ? _buildSkeletonList()
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildNoticeCard(
                      title: 'Annual General Meeting',
                      date: 'June 25, 2026',
                      description: 'The Annual General Meeting for the society will be held in the clubhouse. All members are requested to attend to discuss the upcoming fiscal year budget and society maintenance plans.',
                      isUrgent: true,
                      author: 'Society Admin',
                    ),
                    const SizedBox(height: 16),
                    _buildNoticeCard(
                      title: 'Water Supply Interruption',
                      date: 'June 22, 2026',
                      description: 'Due to municipal maintenance, the water supply will be interrupted between 2:00 PM and 5:00 PM tomorrow. Please store adequate water.',
                      isUrgent: true,
                      author: 'Maintenance Team',
                    ),
                    const SizedBox(height: 16),
                    _buildNoticeCard(
                      title: 'Yoga Classes Starting',
                      date: 'June 20, 2026',
                      description: 'We are starting weekend yoga classes in the central park from 6:30 AM to 7:30 AM. Interested residents can register at the society office.',
                      isUrgent: false,
                      author: 'Cultural Committee',
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(width: 150, height: 16, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                    const Spacer(),
                    Container(width: 50, height: 12, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 200, height: 12, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeCard({
    required String title,
    required String date,
    required String description,
    required bool isUrgent,
    required String author,
  }) {
    return Container(
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
        border: isUrgent ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.3), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
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
