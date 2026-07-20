import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/router/app_routes.dart';
import 'package:society_app/core/api/api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _societyCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _flatController = TextEditingController();
  final _wingController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _isValidatingCode = false;
  Map<String, dynamic>? _detectedSociety;

  @override
  void initState() {
    super.initState();
    _societyCodeController.addListener(_onSocietyCodeChanged);
  }

  void _onSocietyCodeChanged() async {
    final code = _societyCodeController.text.trim();
    if (code.length < 4) {
      if (_detectedSociety != null) {
        setState(() {
          _detectedSociety = null;
          _wingController.clear();
        });
      }
      return;
    }

    setState(() => _isValidatingCode = true);
    final authService = ref.read(authServiceProvider);
    final society = await authService.fetchSocietyByCode(code);
    
    if (mounted) {
      setState(() {
        _isValidatingCode = false;
        _detectedSociety = society;
        if (society != null) {
          final rawWings = List<String>.from(society['wings'] ?? []);
          final parsedWings = <String>[];
          for (var w in rawWings) {
            parsedWings.addAll(w.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
          }
          final wings = parsedWings.toSet().toList();
          _detectedSociety!['wings'] = wings;

          if (wings.isNotEmpty) {
            _wingController.text = wings.first;
          } else {
            _wingController.clear();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _societyCodeController.removeListener(_onSocietyCodeChanged);
    _societyCodeController.dispose();
    _nameController.dispose();
    _flatController.dispose();
    _wingController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_detectedSociety == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid society code. Please check with your society admin.')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);

    context.push(
      AppRoutes.otpVerification,
      extra: {
        'roleName': 'Resident',
        'mobileNumber': _mobileController.text.trim(),
        'isRegistration': true,
        'userName': _nameController.text.trim(),
        'societyId': _detectedSociety!['id'],
        'societyName': _detectedSociety!['name'],
        'societyCode': _detectedSociety!['code'],
        'flatNo': _flatController.text.trim(),
        'wing': _wingController.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Register as a resident of Green Valley Apartments',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Society Invite Code'),
                      _buildTextField(
                        controller: _societyCodeController,
                        hint: 'e.g. GVA-7K9X2',
                        prefix: Icons.qr_code_2,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        validator: (v) => v == null || v.trim().isEmpty ? 'Society code is required' : null,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 12, left: 4),
                        child: Text(
                          'Ask your society admin for the invite code.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                      _buildLabel('Full Name'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Enter your full name',
                        prefix: Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Flat / Unit Number'),
                      _buildTextField(
                        controller: _flatController,
                        hint: 'e.g. 101',
                        prefix: Icons.apartment_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Flat number is required' : null,
                      ),
                      const SizedBox(height: 16),

                      if (_detectedSociety != null && (_detectedSociety!['wings'] as List).isNotEmpty) ...[
                        _buildLabel('Wing'),
                        _buildDropdownField(
                          value: (_detectedSociety!['wings'] as List).contains(_wingController.text)
                              ? _wingController.text
                              : (_detectedSociety!['wings'] as List).first,
                          items: List<String>.from(_detectedSociety!['wings']),
                          prefix: Icons.location_city_outlined,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _wingController.text = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildLabel('Mobile Number'),
                      _buildTextField(
                        controller: _mobileController,
                        hint: 'Enter 10-digit mobile number',
                        prefix: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [LengthLimitingTextInputFormatter(10), FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                          if (v.trim().length != 10) return 'Enter a valid 10-digit mobile number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Email Address'),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'your.email@example.com',
                        prefix: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Terms checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                              activeColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                              child: const Text(
                                'I agree to the Terms of Service and Privacy Policy of Society Connect.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        prefixIcon: Icon(prefix, size: 20, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required IconData prefix,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937))),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(prefix, size: 20, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      ),
    );
  }
}
