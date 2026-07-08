import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/router/app_routes.dart';
import '../../data/models/society.dart';
import '../../data/repository/mock_society_repository.dart';
import '../../../auth/data/models/current_user.dart';
import '../../../auth/data/models/resident.dart';
import '../../../auth/data/repository/mock_resident_repository.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  int _step = 0; // 0: details, 1: plan, 2: payment, 3: success

  // Step 0 - society details
  final _societyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _flatsController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerMobileController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _detailsFormKey = GlobalKey<FormState>();

  // Step 1 - plan selection
  SubscriptionPlan _selectedPlan = SubscriptionPlan.all[1]; // growth default

  // Step 2 - payment mock
  bool _processingPayment = false;

  // Step 3 - success result
  Society? _createdSociety;

  @override
  void dispose() {
    _societyNameController.dispose();
    _addressController.dispose();
    _flatsController.dispose();
    _ownerNameController.dispose();
    _ownerMobileController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (!_detailsFormKey.currentState!.validate()) return;
      // Auto-select plan based on flats
      final flats = int.tryParse(_flatsController.text.trim()) ?? 0;
      _selectedPlan = SubscriptionPlan.all.firstWhere(
        (p) => flats <= p.maxFlats,
        orElse: () => SubscriptionPlan.all.last,
      );
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _processPayment() async {
    setState(() => _processingPayment = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Create owner resident
    final ownerId = 'R${DateTime.now().millisecondsSinceEpoch}';
    final owner = Resident(
      id: ownerId,
      name: _ownerNameController.text.trim(),
      flatNumber: 'OWNER',
      block: '—',
      mobile: _ownerMobileController.text.trim(),
      email: _ownerEmailController.text.trim(),
      isOwner: true,
      isAdmin: true,
    );
    MockResidentRepository.addResident(owner);

    // Create society
    final society = MockSocietyRepository.createSociety(
      name: _societyNameController.text.trim(),
      address: _addressController.text.trim(),
      totalFlats: int.parse(_flatsController.text.trim()),
      ownerId: ownerId,
      planId: _selectedPlan.id,
      amount: _selectedPlan.monthlyPrice,
    );

    // Set current user as owner + admin
    CurrentUser.setUser(
      name: owner.name,
      role: 'resident',
      owner: true,
      admin: true,
      societyId: society.id,
      societyName: society.name,
      societyCode: society.code,
    );

    setState(() {
      _processingPayment = false;
      _createdSociety = society;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: _step == 3 ? null : _back,
        ),
        title: const Text(
          'Register Your Society',
          style: TextStyle(color: Color(0xFF1F2937), fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildStepper(),
              const SizedBox(height: 16),
              Expanded(child: _buildStepContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Society', 'Plan', 'Payment', 'Done'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final completed = _step > i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: completed ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            ),
          );
        }
        final idx = i ~/ 2;
        final isActive = _step >= idx;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF3B82F6) : Colors.white,
                border: Border.all(color: isActive ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB), width: 1.5),
                shape: BoxShape.circle,
              ),
              child: _step > idx
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[idx],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildPlanStep();
      case 2:
        return _buildPaymentStep();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  // ============ STEP 0: SOCIETY DETAILS ============
  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      child: Form(
        key: _detailsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tell us about your society',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            const Text('We\'ll set you up as the owner and admin.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),

            _label('Society Name'),
            _field(_societyNameController, 'e.g. Green Valley Apartments', Icons.apartment_outlined,
                (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 14),

            _label('Society Address'),
            _field(_addressController, 'Full address', Icons.location_on_outlined,
                (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 14),

            _label('Total Flats / Units'),
            _field(_flatsController, 'e.g. 120', Icons.home_work_outlined, (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final n = int.tryParse(v.trim());
              if (n == null || n <= 0) return 'Enter a valid number';
              return null;
            }, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 24),

            const Text('Your Details (Owner & Admin)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            const SizedBox(height: 12),

            _label('Full Name'),
            _field(_ownerNameController, 'Your full name', Icons.person_outline,
                (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 14),

            _label('Mobile Number'),
            _field(_ownerMobileController, '10-digit mobile', Icons.phone_outlined, (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length != 10) return 'Enter 10 digits';
              return null;
            }, keyboardType: TextInputType.phone, formatters: [LengthLimitingTextInputFormatter(10), FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 14),

            _label('Email'),
            _field(_ownerEmailController, 'your.email@example.com', Icons.email_outlined, (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) return 'Invalid email';
              return null;
            }, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),

            _primaryButton('Continue', _next),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============ STEP 1: PLAN SELECTION ============
  Widget _buildPlanStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('Recommended based on ${_flatsController.text} flats.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),

          ...SubscriptionPlan.all.map((plan) => _planCard(plan)),
          const SizedBox(height: 16),

          _primaryButton('Continue to Payment', _next),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _planCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlan.id == plan.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(plan.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(width: 8),
                if (plan.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                    child: const Text('POPULAR',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                  ),
                const Spacer(),
                Text('₹${plan.monthlyPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const Text('/mo', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
            const SizedBox(height: 10),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(top: 4, left: 30),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ============ STEP 2: PAYMENT MOCK ============
  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          const Text('Secure payment processed via Razorpay (mock).',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),

          // Order summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _summaryRow('Society', _societyNameController.text),
                const Divider(height: 20),
                _summaryRow('Plan', '${_selectedPlan.name} (${_selectedPlan.maxFlats} flats)'),
                const Divider(height: 20),
                _summaryRow('Billing', 'Monthly · auto-renew'),
                const Divider(height: 20),
                _summaryRow('Total today',
                    '₹${_selectedPlan.monthlyPrice.toStringAsFixed(0)}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Mock payment methods
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: Color(0xFF3B82F6)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a mock payment for the prototype. Clicking Pay will create your society instantly.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _primaryButton(
            _processingPayment ? 'Processing…' : 'Pay ₹${_selectedPlan.monthlyPrice.toStringAsFixed(0)}',
            _processingPayment ? null : _processPayment,
            loading: _processingPayment,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF1F2937),
              )),
        ),
      ],
    );
  }

  // ============ STEP 3: SUCCESS ============
  Widget _buildSuccessStep() {
    final society = _createdSociety!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 56),
          ),
          const SizedBox(height: 20),
          const Text('Welcome aboard!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 6),
          Text('${society.name} is now active on Society Connect.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 28),

          // Society Code card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Your Society Invite Code',
                    style: TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Text(society.code,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    )),
                const SizedBox(height: 10),
                const Text('Share this code with residents so they can join.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: society.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard'), duration: Duration(seconds: 2)),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                  label: const Text('Copy Code', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _primaryButton('Go to Admin Dashboard', () => context.go(AppRoutes.dashboard)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============ HELPERS ============
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
      );

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon,
    String? Function(String?)? validator, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        prefixIcon: Icon(icon, size: 19, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
