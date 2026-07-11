import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_providers.dart';

class _WaitingVisitor {
  final String id;
  final String name;
  final String type;
  final String flat;
  final String phone;
  final String? approvedBy;
  final String? approvedByName;
  final String time;

  const _WaitingVisitor({
    required this.id,
    required this.name,
    required this.type,
    required this.flat,
    required this.phone,
    this.approvedBy,
    this.approvedByName,
    required this.time,
  });
}

class SecurityWaitingScreen extends ConsumerStatefulWidget {
  const SecurityWaitingScreen({super.key});

  @override
  ConsumerState<SecurityWaitingScreen> createState() => _SecurityWaitingScreenState();
}

class _SecurityWaitingScreenState extends ConsumerState<SecurityWaitingScreen> {
  final _searchController = TextEditingController();
  List<_WaitingVisitor> _visitors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
  }

  Future<void> _fetchVisitors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(visitorServiceProvider);
      // Fetch all visitors with status expected
      final data = await service.listVisitors(status: 'expected');
      setState(() {
        _visitors = data.map((v) {
          final id = v['id'] as String? ?? '';
          final name = v['name'] as String? ?? 'Unknown';
          final type = _capitalize(v['type'] as String? ?? 'guest');
          final flat = v['flat'] as String? ?? 'Flat';
          final phone = v['phone'] as String? ?? 'No phone';
          final approvedBy = v['approved_by'] as String?;
          final approvedByName = v['approved_by_name'] as String?;
          final time = v['expected_time'] ?? v['created_at'] ?? 'N/A';
          
          return _WaitingVisitor(
            id: id,
            name: name,
            type: type,
            flat: flat,
            phone: phone,
            approvedBy: approvedBy,
            approvedByName: approvedByName,
            time: time,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  List<_WaitingVisitor> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _visitors;
    }
    return _visitors.where((v) {
      return v.name.toLowerCase().contains(query) ||
          v.flat.toLowerCase().contains(query) ||
          v.phone.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _markVisitorEntered(String id, String name) async {
    try {
      final service = ref.read(visitorServiceProvider);
      await service.markEntered(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name marked as entered.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchVisitors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark entry: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              'Waiting at Gate',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF1F2937)),
                onPressed: _fetchVisitors,
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Input
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by visitor, flat, or phone...',
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
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
              ),

              // Visitors List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchVisitors,
                  color: const Color(0xFFEAB308),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFEAB308)))
                      : _error != null
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                height: 350,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 44),
                                    const SizedBox(height: 12),
                                    Text('Error: $_error', style: const TextStyle(color: Color(0xFFEF4444)), textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchVisitors,
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAB308)),
                                      child: const Text('Retry', style: TextStyle(color: Colors.black)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _filtered.isEmpty
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    height: 400,
                                    alignment: Alignment.center,
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.hourglass_empty, color: Color(0xFF9CA3AF), size: 48),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No visitors waiting at the gate.',
                                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 15, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filtered.length,
                                  itemBuilder: (context, index) {
                                    final visitor = _filtered[index];
                                    return _buildWaitingVisitorCard(visitor);
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingVisitorCard(_WaitingVisitor visitor) {
    final hasApproval = visitor.approvedBy != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
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
                visitor.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasApproval
                      ? const Color(0xFFECFDF5) // Green
                      : const Color(0xFFFEF3C7), // Yellow/Amber
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasApproval ? 'Approved' : 'Pending Resident',
                  style: TextStyle(
                    color: hasApproval
                        ? const Color(0xFF10B981)
                        : const Color(0xFFD97706),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${visitor.type} • ${visitor.flat}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: ${visitor.phone}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 12),
          
          if (hasApproval)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Approved by resident ${visitor.approvedByName ?? "User"}.',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () => _markVisitorEntered(visitor.id, visitor.name),
              style: FilledButton.styleFrom(
                backgroundColor: hasApproval
                    ? const Color(0xFF10B981)
                    : const Color(0xFF4B5563),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.login, size: 16),
              label: Text(
                hasApproval ? 'Allow Entry' : 'Manual Entry (Bypass)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
