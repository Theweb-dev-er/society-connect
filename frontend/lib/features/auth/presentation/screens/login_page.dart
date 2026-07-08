import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/api/api_providers.dart';
import 'package:society_app/core/router/app_routes.dart';
import '../providers/login_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      final mobile = _mobileController.text.trim();
      setState(() => _isLoading = true);

      try {
        final authService = ref.read(authServiceProvider);
        await authService.sendOtp(mobile);

        if (!mounted) return;
        setState(() => _isLoading = false);

        context.push(
          AppRoutes.otpVerification,
          extra: {
            'roleName': 'Resident',
            'mobileNumber': mobile,
          },
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Privacy Policy'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: isDesktop ? 460 : double.infinity,
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5D5FEF), Color(0xFF8A2BE2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D5FEF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.domain,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Titles
                const Text(
                  'Society Connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Smart Society Management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 40),

                // Welcome Card with Mobile Input
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to continue to your society dashboard',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mobile Number Label
                      const Text(
                        'Mobile Number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🇮🇳', style: TextStyle(fontSize: 20)),
                                  SizedBox(width: 8),
                                  Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('|', style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 20)),
                                ],
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            hintText: '98765 43210',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16, fontWeight: FontWeight.normal),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF5D5FEF), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFEF4444)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (value.length != 10) {
                              return 'Please enter a valid 10 digit number';
                            }
                            return null;
                          },
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Terms checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                              activeColor: const Color(0xFF5D5FEF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: Color(0xFF5D5FEF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: Color(0xFF5D5FEF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Continue Button
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _isLoading || _mobileController.text.length != 10
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF5D5FEF),
                            disabledBackgroundColor: const Color(0xFFC7D2FE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Send OTP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Security Notice
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      'Secure login with OTP verification',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF6B7280).withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New user? ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: const Text(
                        'Register as Resident',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Register society CTA
                GestureDetector(
                  onTap: () => context.push(AppRoutes.subscribe),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business_outlined, size: 18, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Register your Society',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                              Text('Subscribe & become the society admin',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 32),
                // Footer
                const Column(
                  children: [
                    Divider(color: Color(0xFFE5E7EB)),
                    SizedBox(height: 16),
                    Text(
                      'Green Valley Apartments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Powered by Society Connect',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
