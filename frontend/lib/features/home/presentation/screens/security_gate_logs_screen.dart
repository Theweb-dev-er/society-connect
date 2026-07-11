import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_providers.dart';

class SecurityGateLogsScreen extends ConsumerStatefulWidget {
  const SecurityGateLogsScreen({super.key});

  @override
  ConsumerState<SecurityGateLogsScreen> createState() => _SecurityGateLogsScreenState();
}

class _SecurityGateLogsScreenState extends ConsumerState<SecurityGateLogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _error;

  String _selectedDate = 'Today';
  String _selectedType = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final service = ref.read(visitorServiceProvider);
      final data = await service.listGateLogs();
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<dynamic> get _filteredLogs {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return _logs.where((log) {
      // 1. Date Filter
      if (_selectedDate == 'Today') {
        final timestampStr = log['timestamp'] as String?;
        if (timestampStr == null) return false;
        final dt = DateTime.parse(timestampStr).toLocal();
        if (!_isSameDay(dt, today)) return false;
      } else if (_selectedDate == 'Yesterday') {
        final timestampStr = log['timestamp'] as String?;
        if (timestampStr == null) return false;
        final dt = DateTime.parse(timestampStr).toLocal();
        if (!_isSameDay(dt, yesterday)) return false;
      }

      // 2. Visitor Type Filter
      if (_selectedType != 'All') {
        final type = (log['visitor_type'] ?? '') as String;
        if (_selectedType == 'Maid') {
          if (type.toLowerCase() != 'service') return false;
        } else {
          if (type.toLowerCase() != _selectedType.toLowerCase()) return false;
        }
      }

      // 3. Status Filter (Action: entry vs exit)
      if (_selectedStatus != 'All') {
        final action = (log['action'] ?? '') as String;
        if (_selectedStatus == 'Entered' && action != 'entry') return false;
        if (_selectedStatus == 'Exited' && action != 'exit') return false;
      }

      return true;
    }).toList();
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $ampm';
    } catch (_) {
      return timestamp;
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthStr = months[dt.month - 1];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$monthStr ${dt.day}, $hour:$minute $ampm';
    } catch (_) {
      return timestamp;
    }
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
              'Gate Logs',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Color(0xFF1F2937)),
                onPressed: () => _showFilterBottomSheet(context),
              ),
            ],
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3B82F6),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load gate logs: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _fetchLogs();
                },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredLogs;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_outlined, size: 40, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 20),
              const Text(
                'No gate logs found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting the filters above.',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLogs,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final log = filtered[index];
          final type = (log['visitor_type'] ?? '') as String;
          String displayName = log['visitor_name'] ?? 'Unknown';
          if (type.isNotEmpty && !displayName.toLowerCase().contains(type.toLowerCase())) {
            final capitalizedType = type[0].toUpperCase() + type.substring(1);
            displayName = '$displayName ($capitalizedType)';
          }

          final action = (log['action'] ?? 'entry') as String;
          final isEntry = action == 'entry';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLogCard(
              context: context,
              log: log,
              name: displayName,
              action: isEntry ? 'Entered' : 'Exited',
              flat: log['visitor_flat'] ?? 'Unknown Flat',
              time: _formatTime(log['timestamp']),
              isEntry: isEntry,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogCard({
    required BuildContext context,
    required Map<String, dynamic> log,
    required String name,
    required String action,
    required String flat,
    required String time,
    required bool isEntry,
  }) {
    return GestureDetector(
      onTap: () => _showVisitorDetails(context, log),
      child: Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEntry ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEntry ? Icons.arrow_downward : Icons.arrow_upward,
                color: isEntry ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 16,
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
                  const SizedBox(height: 2),
                  Text(
                    '$action • ${flat.startsWith("Flat") ? "" : "Flat "}$flat',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisitorDetails(BuildContext context, Map<String, dynamic> log) {
    final type = (log['visitor_type'] ?? '') as String;
    String displayName = log['visitor_name'] ?? 'Unknown';
    if (type.isNotEmpty && !displayName.toLowerCase().contains(type.toLowerCase())) {
      final capitalizedType = type[0].toUpperCase() + type.substring(1);
      displayName = '$displayName ($capitalizedType)';
    }

    final action = (log['action'] ?? 'entry') as String;
    final isEntry = action == 'entry';

    final entryTimeStr = log['visitor_entry_time'] != null
        ? _formatDate(log['visitor_entry_time'])
        : 'Not recorded';
    final exitTimeStr = log['visitor_exit_time'] != null
        ? _formatDate(log['visitor_exit_time'])
        : 'Not yet exited';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 460),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEntry ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEntry ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isEntry ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isEntry ? "Entered" : "Exited"} at ${_formatTime(log['timestamp'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.apartment, 'Destination', '${(log['visitor_flat'] ?? 'Unknown').toString().startsWith("Flat") ? "" : "Flat "}${log['visitor_flat'] ?? 'Unknown'}'),
            if (log['visitor_phone'] != null && (log['visitor_phone'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailRow(Icons.phone, 'Mobile Number', log['visitor_phone']),
            ],
            if (log['visitor_vehicle_number'] != null && (log['visitor_vehicle_number'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailRow(Icons.directions_car, 'Vehicle Number', log['visitor_vehicle_number']),
            ],
            if (log['visitor_people_count'] != null && (log['visitor_people_count'] as int) > 1) ...[
              const SizedBox(height: 16),
              _buildDetailRow(Icons.group, 'Number of People', log['visitor_people_count'].toString()),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(Icons.login, 'Entry Time', entryTimeStr),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.logout, 'Exit Time', exitTimeStr),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.security, 'Duty Guard', log['guard_name'] ?? 'System'),
            if (log['notes'] != null && (log['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailRow(Icons.notes, 'Notes', log['notes']),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 460),
      builder: (context) {
        String localDate = _selectedDate;
        String localType = _selectedType;
        String localStatus = _selectedStatus;

        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Filter Logs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Date Filter
                  const Text(
                    'Date',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['Today', 'Yesterday', 'All'].map((date) {
                      final isSelected = localDate == date;
                      return ChoiceChip(
                        label: Text(date),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setBottomSheetState(() => localDate = date);
                        },
                        selectedColor: const Color(0xFFECFDF5),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Type Filter
                  const Text(
                    'Visitor Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Guest', 'Delivery', 'Maid'].map((type) {
                      final isSelected = localType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setBottomSheetState(() => localType = type);
                        },
                        selectedColor: const Color(0xFFEFF6FF),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Filter
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Entered', 'Exited'].map((status) {
                      final isSelected = localStatus == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setBottomSheetState(() => localStatus = status);
                        },
                        selectedColor: const Color(0xFFFAF5FF),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFFA855F7) : const Color(0xFF6B7280),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFA855F7) : const Color(0xFFE5E7EB),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = 'Today';
                              _selectedType = 'All';
                              _selectedStatus = 'All';
                            });
                            context.pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          child: const Text('Reset', style: TextStyle(color: Color(0xFF4B5563))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = localDate;
                              _selectedType = localType;
                              _selectedStatus = localStatus;
                            });
                            context.pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
