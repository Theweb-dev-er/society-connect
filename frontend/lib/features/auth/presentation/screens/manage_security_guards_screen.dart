import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_providers.dart';

class ManageSecurityGuardsScreen extends ConsumerStatefulWidget {
  const ManageSecurityGuardsScreen({super.key});

  @override
  ConsumerState<ManageSecurityGuardsScreen> createState() => _ManageSecurityGuardsScreenState();
}

class _ManageSecurityGuardsScreenState extends ConsumerState<ManageSecurityGuardsScreen> {
  List<dynamic> _guards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuards();
  }

  Future<void> _loadGuards() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(guardServiceProvider);
      final data = await service.listGuards();
      setState(() {
        _guards = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addGuard() async {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String gate = 'Gate 1';
    String shift = 'day';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Security Guard', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Full Name', Icons.person_outline),
                const SizedBox(height: 12),
                _field(mobileCtrl, 'Mobile Number', Icons.phone_outlined,
                    inputType: TextInputType.phone,
                    formatters: [LengthLimitingTextInputFormatter(10), FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 12),
                _field(emailCtrl, 'Email (optional)', Icons.email_outlined),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gate,
                  decoration: _dropDeco('Gate'),
                  items: ['Gate 1', 'Gate 2', 'Gate 3']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setDlg(() => gate = v ?? gate),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: shift,
                  decoration: _dropDeco('Shift'),
                  items: [
                    const DropdownMenuItem(value: 'day', child: Text('Day')),
                    const DropdownMenuItem(value: 'night', child: Text('Night')),
                    const DropdownMenuItem(value: 'rotating', child: Text('Rotating')),
                  ],
                  onChanged: (v) => setDlg(() => shift = v ?? shift),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().length != 10) return;
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add Guard'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final service = ref.read(guardServiceProvider);
        await service.createGuard(
          name: nameCtrl.text.trim(),
          phone: mobileCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          gate: gate,
          shift: shift,
        );
        await _loadGuards();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${nameCtrl.text.trim()} added as Security Guard'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add guard: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _updateAccess(dynamic guard, String flag, bool value) async {
    try {
      final service = ref.read(guardServiceProvider);
      await service.updateAccess(
        guard['id'] as String,
        canAddEntry: flag == 'canAddEntry' ? value : null,
        canManagePreApproved: flag == 'canManagePreApproved' ? value : null,
        canViewInsideList: flag == 'canViewInsideList' ? value : null,
        canViewGateLogs: flag == 'canViewGateLogs' ? value : null,
      );
      await _loadGuards();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _toggleActive(dynamic guard) async {
    try {
      final service = ref.read(guardServiceProvider);
      await service.toggleActive(guard['id'] as String);
      await _loadGuards();
      if (!mounted) return;
      final newState = !(guard['is_active'] as bool);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${guard['name']} ${newState ? 'activated' : 'deactivated'}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
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
              'Security Guards',
              style: TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined, color: Color(0xFF22C55E)),
                tooltip: 'Add Guard',
                onPressed: _addGuard,
              ),
            ],
          ),
          body: _isLoading
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
                          ElevatedButton(onPressed: _loadGuards, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _guards.isEmpty
                      ? const Center(child: Text('No security guards added yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _guards.length,
                          itemBuilder: (_, i) => _buildGuardCard(_guards[i]),
                        ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addGuard,
            backgroundColor: const Color(0xFF22C55E),
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text('Add Guard', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildGuardCard(dynamic guard) {
    final isActive = guard['is_active'] as bool;
    final shiftLabel = (guard['shift'] as String? ?? 'day');
    final shiftDisplay = shiftLabel.substring(0, 1).toUpperCase() + shiftLabel.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFFE5E7EB) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Column(
        children: [
          // Guard Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    color: isActive ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guard['name'] as String,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      const SizedBox(height: 2),
                      Text('${guard['gate'] ?? 'Gate 1'} · $shiftDisplay shift · ${guard['phone']}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                // Active / Inactive toggle
                GestureDetector(
                  onTap: () => _toggleActive(guard),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Access Restrictions
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 10),
                const Text('Access Permissions',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                _accessRow(
                  label: 'New Entry',
                  icon: Icons.person_add_alt_1,
                  value: guard['can_add_entry'] as bool,
                  onChanged: (v) => _updateAccess(guard, 'canAddEntry', v),
                ),
                _accessRow(
                  label: 'Pre-Approved Visitors',
                  icon: Icons.verified_user_outlined,
                  value: guard['can_manage_pre_approved'] as bool,
                  onChanged: (v) => _updateAccess(guard, 'canManagePreApproved', v),
                ),
                _accessRow(
                  label: 'Inside List',
                  icon: Icons.meeting_room_outlined,
                  value: guard['can_view_inside_list'] as bool,
                  onChanged: (v) => _updateAccess(guard, 'canViewInsideList', v),
                ),
                _accessRow(
                  label: 'Gate Logs',
                  icon: Icons.history,
                  value: guard['can_view_gate_logs'] as bool,
                  onChanged: (v) => _updateAccess(guard, 'canViewGateLogs', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessRow({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: value ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: value ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                )),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF22C55E),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  InputDecoration _dropDeco(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType inputType = TextInputType.text, List<TextInputFormatter>? formatters}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
