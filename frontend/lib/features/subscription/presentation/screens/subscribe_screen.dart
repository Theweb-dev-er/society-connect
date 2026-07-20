import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/router/app_routes.dart';
import '../../data/models/society.dart';
import '../../../auth/data/models/current_user.dart';
import '../../data/repository/society_service.dart';
import '../../../../core/api/auth_service.dart';

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
  final List<String> _wings = ['Wing A'];
  final _wingInputController = TextEditingController();
  bool _hasMultipleWings = true;
  final List<String> _selectedBhkTypes = ['1BHK', '2BHK', '3BHK'];
  final _bhkInputController = TextEditingController();

  // Step 1 - plan selection
  SubscriptionPlan _selectedPlan = SubscriptionPlan.all[1]; // growth default

  // Step 0 - checking phone
  bool _checkingPhone = false;

  // Step 2 - payment mock
  bool _processingPayment = false;

  // Step 3 - success result
  Society? _createdSociety;

  @override
  void dispose() {
    _societyNameController.dispose();
    _addressController.dispose();
    _flatsController.dispose();
    _wingInputController.dispose();
    _bhkInputController.dispose();
    _ownerNameController.dispose();
    _ownerMobileController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  void _addWing() {
    final text = _wingInputController.text.trim();
    if (text.isNotEmpty) {
      final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      setState(() {
        for (var part in parts) {
          if (!_wings.contains(part)) {
            _wings.add(part);
          }
        }
        _wingInputController.clear();
      });
    }
  }

  void _addBhkType() {
    final text = _bhkInputController.text.trim().toUpperCase();
    const validTypes = ['1RK', '1BHK', '2BHK', '3BHK', '4BHK', '5BHK', '6BHK'];
    if (text.isNotEmpty) {
      final parts = text.split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty);
      setState(() {
        for (var part in parts) {
          if (!validTypes.contains(part)) continue;
          if (!_selectedBhkTypes.contains(part)) {
            _selectedBhkTypes.add(part);
          }
        }
        _bhkInputController.clear();
      });
    }
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (!_detailsFormKey.currentState!.validate()) return;
      
      if (!_hasMultipleWings) {
        _wings.clear();
        _wings.add('Main');
      } else {
        // Auto-add any pending wing text
        if (_wingInputController.text.trim().isNotEmpty) {
          _addWing();
        }

        if (_wings.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add at least one wing (e.g., Wing A).'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Auto-add any pending BHK text
      if (_bhkInputController.text.trim().isNotEmpty) {
        _addBhkType();
      }

      if (_selectedBhkTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one BHK type (e.g., 2BHK).'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if phone number already exists
      final phone = _ownerMobileController.text.trim();
      setState(() => _checkingPhone = true);
      try {
        final exists = await SocietyService().checkPhoneExists(phone);
        if (!mounted) return;
        if (exists) {
          setState(() => _checkingPhone = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This phone number is already registered. Please use a different number.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _checkingPhone = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() => _checkingPhone = false);

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

    try {
      final data = {
        'name': _societyNameController.text.trim(),
        'address': _addressController.text.trim(),
        'total_flats': int.tryParse(_flatsController.text.trim()) ?? 0,
        'wings': _wings,
        'bhk_types': _selectedBhkTypes,
        'owner': {
          'name': _ownerNameController.text.trim(),
          'phone': _ownerMobileController.text.trim(),
          'email': _ownerEmailController.text.trim(),
        }
      };

      final response = await SocietyService().registerSociety(data);
      
      // Update tokens
      if (response.containsKey('access') && response.containsKey('refresh')) {
        await AuthService().saveTokens(response['access'], response['refresh']);
        CurrentUser.accessToken = response['access'];
        CurrentUser.refreshToken = response['refresh'];
      }

      // Set current user
      final user = response['user'];
      CurrentUser.setUser(
        name: user['name'],
        role: user['role'],
        phone: user['phone'],
        owner: true,
        admin: true,
        maker: true,
        checker: true,
        approver: true,
        societyId: user['society'],
        societyName: user['society_name'],
        societyCode: user['society_code'],
        societyWings: List<String>.from(response['society']['wings'] ?? []),
        societyBhkTypes: List<String>.from(response['society']['bhk_types'] ?? []),
        accessToken: response['access'],
        refreshToken: response['refresh'],
      );

      final societyModel = Society(
        id: response['society']['id'],
        name: response['society']['name'],
        code: response['society']['code'],
        address: response['society']['address'] ?? '',
        totalFlats: response['society']['total_flats'] ?? 0,
        ownerId: user['id'],
        createdAt: DateTime.parse(response['society']['created_at']),
        wings: List<String>.from(response['society']['wings'] ?? []),
        bhkTypes: List<String>.from(response['society']['bhk_types'] ?? []),
      );

      if (!mounted) return;
      setState(() {
        _processingPayment = false;
        _createdSociety = societyModel;
        _step = 3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _processingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            const SizedBox(height: 14),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SwitchListTile(
                title: const Text('Does this society have multiple wings?',
                    style: TextStyle(fontSize: 14, color: Color(0xFF1F2937))),
                value: _hasMultipleWings,
                activeColor: const Color(0xFF3B82F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                onChanged: (val) => setState(() => _hasMultipleWings = val),
              ),
            ),
            const SizedBox(height: 14),

            if (_hasMultipleWings) ...[
              _label('Wings (Required)'),
              TextFormField(
                controller: _wingInputController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  hintText: 'e.g. Wing A, Wing B',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.grid_view_outlined, size: 19, color: Color(0xFF9CA3AF)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF3B82F6), size: 22),
                    onPressed: _addWing,
                    tooltip: 'Add wing',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                ),
                onFieldSubmitted: (v) => _addWing(),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Press Enter / Return on your keyboard to add the wing to the list.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ),
              if (_wings.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _wings.map((wing) => Chip(
                    label: Text(wing, style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.w500)),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFDBEAFE)),
                    deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFFef4444)),
                    onDeleted: () => setState(() => _wings.remove(wing)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],

            _label('BHK Types (Required)'),
            TextFormField(
              controller: _bhkInputController,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              textInputAction: TextInputAction.go,
              decoration: InputDecoration(
                hintText: 'e.g. 2BHK, 3BHK',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.bed_outlined, size: 19, color: Color(0xFF9CA3AF)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF3B82F6), size: 22),
                  onPressed: _addBhkType,
                  tooltip: 'Add BHK type',
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
              ),
              onFieldSubmitted: (v) => _addBhkType(),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Press Enter to add. Valid: 1RK, 1BHK, 2BHK, 3BHK, 4BHK, 5BHK, 6BHK',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ),
            if (_selectedBhkTypes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedBhkTypes.map((bhk) => Chip(
                  label: Text(bhk, style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.w500)),
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(color: Color(0xFFDBEAFE)),
                  deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFFef4444)),
                  onDeleted: () => setState(() => _selectedBhkTypes.remove(bhk)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                )).toList(),
              ),
            ],
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

            _primaryButton('Continue', _checkingPhone ? null : _next, loading: _checkingPhone),
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

          _primaryButton('Complete Your Profile', () => context.go(AppRoutes.completeProfile)),
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
