import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/workflow_models.dart';
import '../../data/repository/mock_workflow_repository.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Repairs & Maintenance';
  final _vendorController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _expenseDate = DateTime.now();

  final List<String> _categories = [
    'Repairs & Maintenance',
    'Salaries & Services',
    'Utilities',
    'Vendor Payment',
    'Other',
  ];

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit(bool asDraft) {
    if (!asDraft && !_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final id = 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final item = WorkflowItem(
      id: id,
      type: OperationType.expense,
      title: _descriptionController.text.isNotEmpty ? _descriptionController.text : 'New Expense',
      amount: amount,
      stage: asDraft ? WorkflowStage.draft : WorkflowStage.pendingChecker,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime.now(),
      timeline: [
        AuditEvent(
          at: DateTime.now(),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: asDraft ? 'Saved as draft' : 'Submitted for review',
        ),
      ],
      payload: ExpensePayload(
        category: _selectedCategory,
        vendorName: _vendorController.text,
        description: _descriptionController.text,
        expenseDate: _expenseDate,
        receiptUrl: null,
      ).toMap(),
    );

    MockWorkflowRepository.addItem(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(asDraft ? 'Saved as draft' : 'Submitted for Treasurer review'),
        backgroundColor: asDraft ? const Color(0xFF9CA3AF) : const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Expense Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
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
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF64748B)),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937), fontWeight: FontWeight.w500),
                          items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Vendor / Payee Name'),
                    TextFormField(
                      controller: _vendorController,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      decoration: _inputDecoration('e.g. Vanguard Security Services'),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Amount (Rs.)'),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter amount';
                        if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid amount';
                        return null;
                      },
                      decoration: _inputDecoration('e.g. 45000'),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Expense Date'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 12),
                            Text(
                              '${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Description'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Enter a description' : null,
                      decoration: _inputDecoration('Describe the expense purpose...'),
                    ),
                    const SizedBox(height: 20),

                    // Attachment placeholder
                    _buildLabel('Receipt / Attachment'),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image picker would open here'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, size: 24, color: Color(0xFF64748B)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Upload Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                                  Text('Optional — JPG, PNG, PDF', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After submission, the Treasurer will review this entry before it is approved.',
                        style: TextStyle(fontSize: 12, color: const Color(0xFF1E40AF).withOpacity(0.85), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submit(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _submit(false),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Submit for Review'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
    );
  }
}
