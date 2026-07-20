import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/models/current_user.dart';

class ManageResidentsScreen extends ConsumerStatefulWidget {
  const ManageResidentsScreen({super.key});

  @override
  ConsumerState<ManageResidentsScreen> createState() => _ManageResidentsScreenState();
}

class _ManageResidentsScreenState extends ConsumerState<ManageResidentsScreen> {
  List<dynamic> _residents = [];
  String _search = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(residentServiceProvider);
      final data = await service.listResidents();
      setState(() {
        _residents = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filtered => _residents.where((r) {
    final q = _search.toLowerCase();
    final name = (r['name'] as String? ?? '').toLowerCase();
    final flatNo = (r['flat_no'] as String? ?? '').toLowerCase();
    final phone = r['phone'] as String? ?? '';
    return name.contains(q) || flatNo.contains(q) || phone.contains(q);
  }).toList();

  String? get _adminWorkflowRole {
    for (final r in _residents) {
      if (r['is_admin'] as bool? ?? false) {
        if (r['is_maker'] as bool? ?? false) return 'Maker';
        if (r['is_checker'] as bool? ?? false) return 'Checker';
        if (r['is_approver'] as bool? ?? false) return 'Approver';
      }
    }
    return null;
  }

  bool _canAssignWorkflowRole(dynamic resident, String role) {
    if (resident['is_admin'] as bool? ?? false) return true;
    final flag = role.toLowerCase();
    for (final r in _residents) {
      if (r['id'] == resident['id']) continue;
      if (flag == 'maker' && (r['is_maker'] as bool? ?? false)) return false;
      if (flag == 'checker' && (r['is_checker'] as bool? ?? false)) return false;
      if (flag == 'approver' && (r['is_approver'] as bool? ?? false)) return false;
    }
    return true;
  }

  Future<void> _handleWorkflowRoleToggle(dynamic resident, String role, bool newValue) async {
    if (newValue && !_canAssignWorkflowRole(resident, role)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$role role is already assigned to another resident.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation when assigning workflow role to admin
    final isAdmin = resident['is_admin'] as bool? ?? false;
    if (newValue && isAdmin) {
      final confirmed = await _showRoleAssignmentDialog(resident, role);
      if (!confirmed) return;
    }

    try {
      final service = ref.read(residentServiceProvider);
      final roleLower = role.toLowerCase();
      await service.updateRoles(
        resident['id'] as String,
        isMaker: roleLower == 'maker' ? newValue : null,
        isChecker: roleLower == 'checker' ? newValue : null,
        isApprover: roleLower == 'approver' ? newValue : null,
      );
      await _loadResidents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$role role ${newValue ? 'assigned to' : 'revoked from'} ${resident['name']}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showRoleAssignmentDialog(dynamic resident, String role) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Assign $role Role to Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to assign the $role role to ${resident['name']}, who is already an Admin.'),
            const SizedBox(height: 8),
            const Text('Note: Admin can only hold one workflow role at a time.',
              style: TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  bool get _hasAdmin => _residents.any((r) => r['is_admin'] as bool? ?? false);
  bool get _hasMaker => _residents.any((r) => r['is_maker'] as bool? ?? false);
  bool get _hasChecker => _residents.any((r) => r['is_checker'] as bool? ?? false);
  bool get _hasApprover => _residents.any((r) => r['is_approver'] as bool? ?? false);

  Future<void> _handleAdminToggle(dynamic r, bool newValue) async {
    final isSelf = r['name'] == CurrentUser.name;

    // Self-removal: must transfer admin to someone else
    if (!newValue && isSelf) {
      final transfer = await _showAdminTransferDialog();
      if (transfer == null) return;

      try {
        final service = ref.read(residentServiceProvider);
        // Single atomic transfer endpoint (avoids permission issues)
        await service.transferAdmin(
          fromResidentId: r['id'] as String,
          toResidentId: transfer['residentId'] as String,
          reason: transfer['reason'] as String? ?? '',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin access has been transferred. You have been logged out.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 4),
          ),
        );
        // Clear auth and go to login after snackbar is visible
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        CurrentUser.clear();
        context.go(AppRoutes.login);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Normal assign/revoke (not self)
    final reason = await _askReason(
      title: newValue ? 'Assign Admin Role' : 'Revoke Admin Role',
      message: newValue
          ? 'You are about to make ${r['name']} the society Admin. Please provide a reason for this transfer.'
          : 'You are about to revoke Admin from ${r['name']}. Please provide a reason.',
    );
    if (reason == null || reason.trim().isEmpty) return;

    try {
      final service = ref.read(residentServiceProvider);
      await service.updateRoles(r['id'] as String, isAdmin: newValue);
      await _loadResidents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue
              ? '${r['name']} is now Admin. Reason logged.'
              : 'Admin revoked from ${r['name']}. Reason logged.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getResidentRoleLabel(dynamic r) {
    if (r['is_maker'] as bool? ?? false) return 'Maker';
    if (r['is_checker'] as bool? ?? false) return 'Checker';
    if (r['is_approver'] as bool? ?? false) return 'Approver';
    return '';
  }

  Future<Map<String, dynamic>?> _showAdminTransferDialog() async {
    final others = _residents.where((x) {
      final isAdmin = x['is_admin'] as bool? ?? false;
      final isSelf = x['name'] == CurrentUser.name;
      return !isAdmin && !isSelf;
    }).toList();
    dynamic selected;
    final reasonController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          insetPadding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Transfer Admin Access', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: isMobile ? double.infinity : 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You are removing your own admin access. Select a resident to transfer admin to:', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 12),
                Container(
                  constraints: BoxConstraints(maxHeight: isMobile ? 180 : 220),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(10)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: others.length,
                    itemBuilder: (_, i) {
                      final o = others[i];
                      final isSelected = selected != null && selected['id'] == o['id'];
                      final roleLabel = _getResidentRoleLabel(o);
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(o['name'] as String? ?? '', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                            ),
                            if (roleLabel.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleLabel == 'Maker'
                                      ? const Color(0xFFFAF5FF)
                                      : roleLabel == 'Checker'
                                          ? const Color(0xFFFFFBEB)
                                          : const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: roleLabel == 'Maker'
                                    ? const Color(0xFF8B5CF6)
                                    : roleLabel == 'Checker'
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF8B5CF6))),
                              ),
                          ],
                        ),
                        subtitle: Text('${o['flat_no']}  |  ${o['phone']}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        leading: Icon(Icons.person, size: 22, color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF)),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 20) : null,
                        onTap: () => setDialogState(() => selected = o),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Reason for transfer (required)',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (isMobile)
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: selected == null || reasonController.text.trim().isEmpty
                          ? null
                          : () => Navigator.pop(ctx, {'residentId': selected['id'] as String, 'reason': reasonController.text.trim()}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Transfer & Logout'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: selected == null || reasonController.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(ctx, {'residentId': selected['id'] as String, 'reason': reasonController.text.trim()}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Transfer & Logout'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askReason({required String title, required String message}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Stepping down due to relocation',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm'),
          ),
        ],
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
              'Manage Residents',
              style: TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.w600),
            ),
            centerTitle: false,
            actions: [
              if (CurrentUser.role == 'admin' || CurrentUser.isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add, color: Color(0xFF3B82F6)),
                  onSelected: (value) {
                    if (value == 'manual') {
                      _showManualAddSheet();
                    } else if (value == 'csv') {
                      _importCSV();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'manual',
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt, size: 20, color: Color(0xFF374151)),
                          SizedBox(width: 8),
                          Text('Add Manually'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'csv',
                      child: Row(
                        children: [
                          Icon(Icons.upload_file, size: 20, color: Color(0xFF374151)),
                          SizedBox(width: 8),
                          Text('Import CSV'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Single Admin Policy Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add, size: 20, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Single Admin Policy',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const Text(
                            'Only one admin per society. Admin can also hold one workflow role.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_adminWorkflowRole != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Admin is $_adminWorkflowRole',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search residents...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('Resident', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF)))),
                    Expanded(child: Center(child: Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))))),
                    Expanded(child: Center(child: Text('Maker', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))))),
                    Expanded(child: Center(child: Text('Checker', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))))),
                    Expanded(child: Center(child: Text('Approver', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))))),
                  ],
                ),
              ),
              const Divider(height: 24, indent: 16, endIndent: 16, color: Color(0xFFE5E7EB)),

              // List
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
                                ElevatedButton(onPressed: _loadResidents, child: const Text('Retry')),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filtered.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final r = _filtered[index];
                              return _buildResidentCard(r);
                            },
                          ),
              ),

              // Footer info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Color(0xFF3B82F6)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Each society has one Admin who can also hold exactly one workflow role (Maker/Checker/Approver). Admin transfers require a reason and are logged.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                        ),
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

  Widget _buildResidentCard(dynamic r) {
    final isAdmin = r['is_admin'] as bool? ?? false;
    final isMaker = r['is_maker'] as bool? ?? false;
    final isChecker = r['is_checker'] as bool? ?? false;
    final isApprover = r['is_approver'] as bool? ?? false;
    final isOwner = r['is_owner'] as bool? ?? false;
    final name = r['name'] as String? ?? 'Unknown';
    final phone = r['phone'] as String? ?? '';
    final flatNo = r['flat_no'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                    const SizedBox(height: 2),
                    Text(flatNo, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: (!_hasAdmin || isAdmin)
                      ? Switch(
                          value: isAdmin,
                          onChanged: (v) => _handleAdminToggle(r, v),
                          activeColor: const Color(0xFF10B981),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      : const Text('—', style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 16)),
                ),
              ),
              Expanded(
                child: Center(
                  child: (!_hasMaker || isMaker) && _canAssignWorkflowRole(r, 'Maker')
                      ? Switch(
                          value: isMaker,
                          onChanged: (v) => _handleWorkflowRoleToggle(r, 'Maker', v),
                          activeColor: const Color(0xFF8B5CF6),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      : const Text('—', style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 16)),
                ),
              ),
              Expanded(
                child: Center(
                  child: (!_hasChecker || isChecker) && _canAssignWorkflowRole(r, 'Checker')
                      ? Switch(
                          value: isChecker,
                          onChanged: (v) => _handleWorkflowRoleToggle(r, 'Checker', v),
                          activeColor: const Color(0xFFF59E0B),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      : const Text('—', style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 16)),
                ),
              ),
              Expanded(
                child: Center(
                  child: (!_hasApprover || isApprover) && _canAssignWorkflowRole(r, 'Approver')
                      ? Switch(
                          value: isApprover,
                          onChanged: (v) => _handleWorkflowRoleToggle(r, 'Approver', v),
                          activeColor: const Color(0xFF8B5CF6),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      : const Text('—', style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 16)),
                ),
              ),
            ],
          ),
          if (isOwner || isAdmin || isMaker || isChecker || isApprover)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (isOwner) _buildRolePill('Owner', const Color(0xFF0EA5E9), const Color(0xFFE0F2FE)),
                  if (isAdmin) _buildRolePill('Admin', const Color(0xFF10B981), const Color(0xFFD1FAE5)),
                  if (isMaker) _buildRolePill('Maker', const Color(0xFF8B5CF6), const Color(0xFFFAF5FF)),
                  if (isChecker) _buildRolePill('Checker', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                  if (isApprover) _buildRolePill('Approver', const Color(0xFF8B5CF6), const Color(0xFFEDE9FE)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRolePill(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  void _showManualAddSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final wingController = TextEditingController();
    final flatNoController = TextEditingController();
    
    final wings = CurrentUser.societyWings ?? [];
    String? selectedWing = wings.isNotEmpty ? wings.first : null;
    final bhkOptions = (CurrentUser.societyBhkTypes?.isNotEmpty ?? false)
        ? CurrentUser.societyBhkTypes!
        : ['1RK', '1BHK', '2BHK', '3BHK', '4BHK', '5BHK', '6BHK'];
    String? selectedBhk = bhkOptions.isNotEmpty ? bhkOptions.first : '2BHK';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Resident Manually', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 24),
                _buildTextField('Full Name', nameController),
                const SizedBox(height: 16),
                _buildTextField('Phone Number (10 digits)', phoneController, keyboardType: TextInputType.phone, maxLength: 10),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: wings.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Wing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedWing,
                                      isExpanded: true,
                                      items: wings.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                                      onChanged: (v) => setSheetState(() => selectedWing = v),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildTextField('Wing (e.g. A)', wingController),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Flat No (e.g. 101)', flatNoController)),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Flat Type (BHK)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBhk,
                          isExpanded: true,
                          items: bhkOptions
                              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (v) => setSheetState(() => selectedBhk = v),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () async {
                      final wingValue = wings.isNotEmpty ? selectedWing : wingController.text;
                      if (nameController.text.isEmpty || phoneController.text.isEmpty || (wingValue == null || wingValue.isEmpty) || flatNoController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
                        return;
                      }
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      try {
                        final service = ref.read(residentServiceProvider);
                        await service.addResidentManually(
                          nameController.text.trim(),
                          phoneController.text.trim(),
                          wingValue!.trim(),
                          flatNoController.text.trim(),
                          true, // Automatically set as owner
                          bhkType: selectedBhk,
                        );
                        _loadResidents();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident added successfully!')));
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Add Resident'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          ),
        ),
      ],
    );
  }

  Future<void> _importCSV() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Residents (CSV)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your CSV file must include exactly these columns in order:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: const Text('Name, Phone, Wing, Flat Number, Is Owner, BHK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 8),
            const Text('Example:'),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: const Text('John Doe, 9876543210, Wing A, 101, Yes, 2BHK\nJane Smith, 9876543211, Liberty, 204, Yes, 3BHK', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final csvData = "Name, Phone, Wing, Flat Number, Is Owner, BHK\nJohn Doe, 9876543210, Wing A, 101, Yes, 2BHK\nJane Smith, 9876543211, Liberty, 204, Yes, 3BHK";
                final bytes = Uint8List.fromList(utf8.encode(csvData));
                await FilePicker.saveFile(
                  dialogTitle: 'Save CSV Template',
                  fileName: 'resident_import_template.csv',
                  type: FileType.custom,
                  allowedExtensions: ['csv'],
                  bytes: bytes,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template downloaded successfully!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
                }
              }
            },
            child: const Text('Download Template'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAndUploadCSV();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadCSV() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isLoading = true);
      final file = result.files.first;
      
      final service = ref.read(residentServiceProvider);
      final response = await service.importResidentsCSV(file);
      
      _loadResidents();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text('${response['detail']}\n\nErrors:\n${(response['errors'] as List).join('\n')}'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
