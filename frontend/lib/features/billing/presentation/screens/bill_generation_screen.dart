import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/billing_service.dart';
import '../../../../core/api/resident_service.dart';
import '../../../../core/router/app_routes.dart';

final billingServiceProvider = Provider<BillingService>((ref) => BillingService());
final residentServiceProvider = Provider<ResidentService>((ref) => ResidentService());

class BillGenerationScreen extends ConsumerStatefulWidget {
  const BillGenerationScreen({super.key});

  @override
  ConsumerState<BillGenerationScreen> createState() => _BillGenerationScreenState();
}

class _BillGenerationScreenState extends ConsumerState<BillGenerationScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _residents = [];
  Map<String, dynamic> _template = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  String _selectedMonth = 'January';
  String _selectedYear = '2026';
  bool _isRecurring = false;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _years = ['2025', '2026', '2027', '2028'];

  final Map<String, Map<String, TextEditingController>> _rateControllers = {};
  final List<String> _bhkTypes = ['1RK', '1BHK', '2BHK', '3BHK', '4BHK', '5BHK'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final billingService = ref.read(billingServiceProvider);
      final residentService = ref.read(residentServiceProvider);

      final categories = await billingService.listCategories();
      final residents = await residentService.listResidents();
      final template = await billingService.getBillTemplate();

      setState(() {
        _categories = categories.where((c) => c['is_active'] == true).toList();
        _residents = residents;
        _template = template;
        _isRecurring = template['is_recurring'] as bool? ?? false;
        _initControllers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  void _initControllers() {
    final rates = _template['rates'] as Map<String, dynamic>? ?? {};
    for (final cat in _categories) {
      final catId = cat['id'] as String;
      final catRates = rates[catId] as Map<String, dynamic>? ?? {};
      _rateControllers[catId] = {};
      for (final bhk in _bhkTypes) {
        final value = catRates[bhk] as num? ?? 0;
        _rateControllers[catId]![bhk] = TextEditingController(
          text: value > 0 ? value.toString() : '',
        );
      }
    }
  }

  Map<String, double> _getRatesForCategory(String catId) {
    final controllers = _rateControllers[catId];
    if (controllers == null) return {};
    final result = <String, double>{};
    for (final entry in controllers.entries) {
      final val = double.tryParse(entry.value.text) ?? 0;
      if (val > 0) result[entry.key] = val;
    }
    return result;
  }

  Map<String, int> _getResidentCountByBhk() {
    final counts = <String, int>{};
    for (final bhk in _bhkTypes) {
      counts[bhk] = 0;
    }
    for (final resident in _residents) {
      final bhk = resident['bhk_type'] as String? ?? '2BHK';
      if (counts.containsKey(bhk)) {
        counts[bhk] = counts[bhk]! + 1;
      }
    }
    return counts;
  }

  double _calculateCategoryTotal(String catId) {
    final rates = _getRatesForCategory(catId);
    final counts = _getResidentCountByBhk();
    double total = 0;
    for (final entry in rates.entries) {
      total += entry.value * (counts[entry.key] ?? 0);
    }
    return total;
  }

  double _calculateGrandTotal() {
    double total = 0;
    for (final cat in _categories) {
      total += _calculateCategoryTotal(cat['id'] as String);
    }
    return total;
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final billingService = ref.read(billingServiceProvider);

      final rates = <String, dynamic>{};
      for (final cat in _categories) {
        final catId = cat['id'] as String;
        final catRates = _getRatesForCategory(catId);
        if (catRates.isNotEmpty) {
          rates[catId] = catRates;
        }
      }

      final counts = _getResidentCountByBhk();
      final entries = <Map<String, dynamic>>[];
      for (final resident in _residents) {
        final bhk = resident['bhk_type'] as String? ?? '2BHK';
        final categoryAmounts = <String, double>{};
        double residentTotal = 0;
        for (final cat in _categories) {
          final catId = cat['id'] as String;
          final catRates = _getRatesForCategory(catId);
          final amount = catRates[bhk] ?? 0;
          categoryAmounts[cat['name'] as String] = amount;
          residentTotal += amount;
        }
        entries.add({
          'flat': '${resident['wing'] ?? ''} - ${resident['flat_no'] ?? ''}',
          'residentName': resident['name'] ?? 'Unknown',
          'bhkType': bhk,
          'categoryAmounts': categoryAmounts,
          'total': residentTotal,
        });
      }

      final payload = <String, dynamic>{
        'bill_period': {'month': _selectedMonth, 'year': _selectedYear},
        'categories': _categories.map((cat) {
          final catId = cat['id'] as String;
          return {
            'category_id': catId,
            'category_name': cat['name'] as String,
            'rates': _getRatesForCategory(catId),
          };
        }).toList(),
        'entries': entries,
        'total_amount': _calculateGrandTotal(),
        'resident_count': _residents.length,
      };

      final title = '$_selectedMonth $_selectedYear Maintenance Bill';
      await billingService.createWorkflowItem(
        type: 'bill',
        title: title,
        amount: _calculateGrandTotal(),
        description: 'Monthly maintenance bill for $_selectedMonth $_selectedYear',
        payload: payload,
      );

      await billingService.updateBillTemplate(
        rates: rates,
        isRecurring: _isRecurring,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill generated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Generate Bill',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 17, fontWeight: FontWeight.w600),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFE4E4E7), height: 1),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        children: [
                          const Text('Billing Cycle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          const SizedBox(height: 16),
                          _buildPeriodSelector(),
                          const SizedBox(height: 32),
                          
                          _buildRecurringToggle(),
                          const SizedBox(height: 32),
                          const Divider(color: Color(0xFFE4E4E7)),
                          const SizedBox(height: 24),
                          
                          _buildCategoriesSection(),
                          const SizedBox(height: 32),
                          const Divider(color: Color(0xFFE4E4E7)),
                          const SizedBox(height: 24),
                          
                          const Text('Invoice Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          const SizedBox(height: 16),
                          _buildPreviewSection(),
                        ],
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E4E7))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total Due', style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('₹${_calculateGrandTotal().toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: _isSubmitting
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                  : FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Generate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildFlatDropdown(_selectedMonth, _months, (v) => setState(() => _selectedMonth = v!)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFlatDropdown(_selectedYear, _years, (v) => setState(() => _selectedYear = v!)),
        ),
      ],
    );
  }

  Widget _buildFlatDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: Color(0xFF3B82F6)),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRecurringToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auto-Generate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            SizedBox(height: 4),
            Text('Repeat this bill every month', style: TextStyle(fontSize: 14, color: Color(0xFF71717A))),
          ],
        ),
        Switch.adaptive(
          value: _isRecurring,
          onChanged: (v) => setState(() => _isRecurring = v),
          activeColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFA1A1AA)),
            const SizedBox(height: 16),
            const Text('No Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text('Please set up billing categories first.', style: TextStyle(color: Color(0xFF71717A), fontSize: 14)),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                await context.push(AppRoutes.manageBillingCategories);
                _loadData();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Manage Categories'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Category Rates', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            TextButton(
              onPressed: () async {
                await context.push(AppRoutes.manageBillingCategories);
                _loadData();
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
              child: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._categories.map((cat) => _buildCategoryCard(cat)),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final catId = cat['id'] as String;
    final controllers = _rateControllers[catId] ?? {};

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cat['name'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          if (cat['description'] != null && (cat['description'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(cat['description'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF71717A))),
            )
          else
            const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _bhkTypes.map((bhk) {
              return SizedBox(
                width: 100,
                child: TextField(
                  controller: controllers[bhk],
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    labelText: bhk,
                    labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                    filled: true,
                    fillColor: const Color(0xFFF4F4F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final counts = _getResidentCountByBhk();
    final grandTotal = _calculateGrandTotal();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _bhkTypes.where((bhk) => counts[bhk]! > 0).map((bhk) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFBFDBFE)), borderRadius: BorderRadius.circular(20)),
                child: Text('$bhk: ${counts[bhk]}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E40AF))),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ..._categories.map((cat) {
            final total = _calculateCategoryTotal(cat['id'] as String);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cat['name'] as String, style: const TextStyle(fontSize: 15, color: Color(0xFF334155))),
                  Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                ],
              ),
            );
          }),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFBFDBFE)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Est.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
            ],
          ),
        ],
      ),
    );
  }
}
