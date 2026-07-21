import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/billing_service.dart';
import '../../../../core/router/app_routes.dart';

final billingServiceProvider = Provider<BillingService>((ref) => BillingService());

class BillsListScreen extends ConsumerStatefulWidget {
  const BillsListScreen({super.key});

  @override
  ConsumerState<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends ConsumerState<BillsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allBills = [];
  bool _isLoading = true;
  String? _error;

  String _selectedMonth = 'July';
  String _selectedYear = '2026';

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _years = ['2025', '2026', '2027', '2028'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBills() async {
    try {
      final service = ref.read(billingServiceProvider);
      final data = await service.listWorkflowItems(type: 'bill');
      setState(() {
        _allBills = data;
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

  List<dynamic> get _monthlyBills {
    return _allBills.where((b) {
      final payload = b['payload'] as Map<String, dynamic>? ?? {};
      final period = payload['bill_period'] as Map<String, dynamic>? ?? {};
      return period['month'] == _selectedMonth && period['year'] == _selectedYear;
    }).toList();
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  double _totalAmount(List<dynamic> bills) {
    return bills.fold<double>(0, (sum, b) => sum + _parseAmount(b['amount']));
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'draft':        return const Color(0xFF3B82F6);
      case 'pending_checker': return const Color(0xFFF59E0B);
      case 'pending_approver': return const Color(0xFFF97316);
      case 'approved':     return const Color(0xFF10B981);
      case 'rejected':     return const Color(0xFFEF4444);
      default:             return const Color(0xFF6B7280);
    }
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'draft':           return 'Draft';
      case 'pending_checker': return 'Pending Review';
      case 'pending_approver': return 'Pending Approval';
      case 'approved':        return 'Approved';
      case 'rejected':        return 'Rejected';
      default:                return stage;
    }
  }

  IconData _stageIcon(String stage) {
    switch (stage) {
      case 'draft':           return Icons.edit_note;
      case 'pending_checker': return Icons.fact_check;
      case 'pending_approver': return Icons.gavel;
      case 'approved':        return Icons.check_circle;
      case 'rejected':        return Icons.cancel;
      default:                return Icons.receipt;
    }
  }

  Widget _buildSummaryCard(List<dynamic> bills) {
    final total = _totalAmount(bills);
    final count = bills.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1 ? '$count Bill' : '$count Bills',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 360;

    final monthDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, size: 18, color: Color(0xFF6B7280)),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13),
          items: _months.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _selectedMonth = v!),
        ),
      ),
    );

    final yearDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, size: 18, color: Color(0xFF6B7280)),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13),
          items: _years.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedYear = v!),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: isCompact
          ? Column(
              children: [
                monthDropdown,
                const SizedBox(height: 8),
                yearDropdown,
              ],
            )
          : Row(
              children: [
                Expanded(child: monthDropdown),
                const SizedBox(width: 10),
                Expanded(child: yearDropdown),
              ],
            ),
    );
  }

  Widget _buildBillCard(dynamic bill) {
    final stage = bill['stage'] as String? ?? 'draft';
    final title = bill['title'] as String? ?? 'Untitled';
    final amount = _parseAmount(bill['amount']);
    final submittedBy = bill['submitted_by_name'] as String? ?? 'Unknown';
    final submittedAt = _formatDate(bill['submitted_at'] as String?);
    final payload = bill['payload'] as Map<String, dynamic>? ?? {};
    final period = payload['bill_period'] as Map<String, dynamic>? ?? {};
    final periodLabel = '${period['month'] ?? ''} ${period['year'] ?? ''}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          String role = 'checker';
          if (stage == 'pending_approver') role = 'approver';
          context.push(AppRoutes.approvalDetail, extra: {'id': bill['id'], 'role': role});
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _stageColor(stage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_stageIcon(stage), size: 16, color: _stageColor(stage)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          periodLabel.isNotEmpty ? periodLabel : 'No period',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _stageColor(stage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _stageLabel(stage),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _stageColor(stage)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline, size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Text(
                              submittedBy,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Text(
                              submittedAt.isNotEmpty ? submittedAt : 'Draft',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 15, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> bills) {
    if (bills.isEmpty) {
      return _buildEmptyState('No bills found');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: bills.length,
      itemBuilder: (context, index) => _buildBillCard(bills[index]),
    );
  }

  Widget _buildTabContent({bool isMonthly = false}) {
    final bills = isMonthly ? _monthlyBills : _allBills;
    return Column(
      children: [
        if (isMonthly) _buildMonthYearSelector(),
        _buildSummaryCard(bills),
        Expanded(child: _buildList(bills)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Bills',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: const Color(0xFF3B82F6),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Monthly'),
                Tab(text: 'All Bills'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Color(0xFFEF4444)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(isMonthly: true),
                    _buildTabContent(isMonthly: false),
                  ],
                ),
    );
  }
}
