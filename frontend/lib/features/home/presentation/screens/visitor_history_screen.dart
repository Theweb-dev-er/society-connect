import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/widgets/common_states.dart';

class VisitorHistoryScreen extends StatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = false;

  Future<void> _refreshHistory() async {
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
              'Visitor History',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),
          body: Column(
            children: [
              // Search and Filters Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search visitors...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Guest'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Delivery'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Maid'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Vendor'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // History List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshHistory,
                  color: const Color(0xFF3B82F6),
                  child: _isLoading 
                    ? const LoadingState(message: 'Fetching logs...')
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _buildHistoryCard(
                            name: 'Amit Kumar',
                            type: 'Delivery',
                            datetime: 'May 18, 2026 • 2:30 PM',
                            status: 'Approved',
                            icon: Icons.face,
                          ),
                          const SizedBox(height: 12),
                          _buildHistoryCard(
                            name: 'Sunita Devi',
                            type: 'Maid',
                            datetime: 'May 18, 2026 • 8:00 AM',
                            status: 'Approved',
                            icon: Icons.face_3,
                          ),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String name,
    required String type,
    required String datetime,
    required String status,
    required IconData icon,
  }) {
    final isApproved = status == 'Approved';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF), // Light purple
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFD97706), // brownish/yellowish for avatars
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: isApproved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: isApproved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text(
                      datetime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
