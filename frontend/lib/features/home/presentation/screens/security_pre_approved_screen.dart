import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_providers.dart';

class _Visitor {
  final String name;
  final String type;
  final String flat;
  final String expectedTime;

  const _Visitor({
    required this.name,
    required this.type,
    required this.flat,
    required this.expectedTime,
  });
}

class SecurityPreApprovedScreen extends ConsumerStatefulWidget {
  const SecurityPreApprovedScreen({super.key});

  @override
  ConsumerState<SecurityPreApprovedScreen> createState() => _SecurityPreApprovedScreenState();
}

class _SecurityPreApprovedScreenState extends ConsumerState<SecurityPreApprovedScreen> {
  String _filter = 'All';
  final _searchController = TextEditingController();
  List<_Visitor> _visitors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
  }

  Future<void> _fetchVisitors() async {
    try {
      final service = ref.read(visitorServiceProvider);
      final data = await service.listVisitors(status: 'expected');
      setState(() {
        _visitors = data.map((v) => _Visitor(
          name: v['name'] as String,
          type: _capitalize(v['type'] as String),
          flat: v['flat'] as String,
          expectedTime: v['expected_time'] ?? 'N/A',
        )).toList();
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  List<_Visitor> get _filtered {
    var result = _filter == 'All'
        ? List<_Visitor>.from(_visitors)
        : _visitors.where((v) => v.type == _filter).toList();

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((v) => v.name.toLowerCase().contains(query)).toList();
    }
    return result;
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
              'Pre-Approved Visitors',
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
              // Search bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by visitor name...',
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
              ),
              // Filter chips
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Guest', 'Delivery', 'Service'].map((type) {
                      final isSelected = _filter == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _filter = type),
                          selectedColor: const Color(0xFF3B82F6),
                          backgroundColor: const Color(0xFFF3F4F6),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF374151),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Count
              Container(
                color: const Color(0xFFF8F9FA),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${_filtered.length} ${_filtered.length == 1 ? 'visitor' : 'visitors'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                    ),
                    if (_filter != 'All')
                      GestureDetector(
                        onTap: () => setState(() => _filter = 'All'),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text('Clear filter', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
              // Cards list
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
                                ElevatedButton(
                                  onPressed: _fetchVisitors,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No visitors for this filter.',
                                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildPreApprovedCard(
                                    context,
                                    name: _filtered[i].name,
                                    type: _filtered[i].type,
                                    flat: _filtered[i].flat,
                                    expectedTime: _filtered[i].expectedTime,
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreApprovedCard(
    BuildContext context, {
    required String name,
    required String type,
    required String flat,
    required String expectedTime,
  }) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Expected',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$type • $flat',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                expectedTime,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visitor Marked as Entered')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Mark as Entered'),
            ),
          ),
        ],
      ),
    );
  }
}
