import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/api/api_providers.dart';
import 'package:society_app/core/router/app_routes.dart';
import '../../data/models/current_user.dart';
import '../../../../services/notification_service.dart';


class OtpVerificationPage extends ConsumerStatefulWidget {
  final String roleName;
  final String mobileNumber;
  final bool isRegistration;
  final String? userName;
  final String? societyId;
  final String? societyName;
  final String? societyCode;
  final String? flatNo;
  final String? wing;

  const OtpVerificationPage({
    super.key,
    required this.roleName,
    required this.mobileNumber,
    this.isRegistration = false,
    this.userName,
    this.societyId,
    this.societyName,
    this.societyCode,
    this.flatNo,
    this.wing,
  });

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.verifyOtp(widget.mobileNumber, otp);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final user = result['user'] as Map<String, dynamic>?;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
        return;
      }

      final role = (user['role'] as String?) ?? 'resident';
      final isNewUser = result['is_new_user'] as bool? ?? false;

      if (isNewUser && widget.isRegistration) {
        // New registration flow
        final data = {
          'flat_no': widget.flatNo,
          'is_owner': false,
          'name': widget.userName,
        };
        if (widget.wing != null && widget.wing!.isNotEmpty) {
          data['wing'] = widget.wing;
        }
        if (widget.societyId != null) {
          data['society_id'] = widget.societyId;
        } else if (widget.societyCode != null) {
          data['society_code'] = widget.societyCode;
        }

        try {
          await authService.createResidentProfile(data);
          await authService.fetchMe();
        } catch (e) {
          // Ignore, they can complete profile later
        }

        NotificationService().initialize();
        context.go(AppRoutes.dashboard);
        return;
      }

      NotificationService().initialize();

      // Check if profile needs completion (no flatNo but not a guard)
      if (CurrentUser.flatNo == null && role != 'security_guard') {
        context.go(AppRoutes.completeProfile);
        return;
      }
      if (role == 'security_guard') {
        if (CurrentUser.guardCanAddEntry || CurrentUser.guardCanManagePreApproved ||
            CurrentUser.guardCanViewInsideList || CurrentUser.guardCanViewGateLogs) {
          context.go(AppRoutes.securityDashboard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. No guard permissions assigned.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _getRoleTheme() {
    switch (widget.roleName.toLowerCase()) {
      case 'resident':
        return {
          'icon': Icons.home_outlined,
          'color': const Color(0xFF3B82F6),
          'bgColor': const Color(0xFFEFF6FF),
        };
      case 'admin / secretary':
        return {
          'icon': Icons.manage_accounts_outlined,
          'color': const Color(0xFFA855F7),
          'bgColor': const Color(0xFFFAF5FF),
        };
      case 'security guard':
        return {
          'icon': Icons.security_outlined,
          'color': const Color(0xFF22C55E),
          'bgColor': const Color(0xFFF0FDF4),
        };
      default:
        return {
          'icon': Icons.person_outline,
          'color': const Color(0xFF3B82F6),
          'bgColor': const Color(0xFFEFF6FF),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final roleTheme = _getRoleTheme();

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
            width: isDesktop ? 460 : double.infinity,
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: roleTheme['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            roleTheme['icon'] as IconData,
                            color: roleTheme['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.roleName.toLowerCase() == 'user'
                                  ? 'Verification'
                                  : 'Logging in as',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              widget.roleName.toLowerCase() == 'user'
                                  ? 'Phone Number'
                                  : widget.roleName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // OTP Details
                const Text(
                  'OTP sent to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+91 ${widget.mobileNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 48),

                // OTP Input Field Title
                const Text(
                  'Enter 6-Digit OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),

                // OTP Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF5D5FEF), width: 1.5),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                            }
                          } else {
                            if (index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          }
                          // Automatically submit when all are filled
                          final otp = _otpControllers.map((c) => c.text).join();
                          if (otp.length == 6) {
                            _verifyOtp();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Resend OTP in ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '30s',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B82F6).withOpacity(0.9), // Soft blue
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6), // Bright purple
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verify & Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
