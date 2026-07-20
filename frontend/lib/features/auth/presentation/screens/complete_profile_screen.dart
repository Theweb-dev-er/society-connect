import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/router/app_routes.dart';
import 'package:society_app/core/api/api_providers.dart';
import '../../data/models/current_user.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _societyCodeController = TextEditingController();
  final _flatController = TextEditingController();
  final _wingController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _detectedSociety;
  
  @override
  void initState() {
    super.initState();
    if (CurrentUser.societyCode != null) {
      _societyCodeController.text = CurrentUser.societyCode!;
      _fetchSociety(CurrentUser.societyCode!);
    } else {
      _societyCodeController.addListener(_onSocietyCodeChanged);
    }
  }

  void _onSocietyCodeChanged() {
    final code = _societyCodeController.text.trim();
    if (code.length >= 4) {
      _fetchSociety(code);
    }
  }

  Future<void> _fetchSociety(String code) async {
    final authService = ref.read(authServiceProvider);
    final society = await authService.fetchSocietyByCode(code);
    if (mounted && society != null) {
      setState(() {
        _detectedSociety = society;
        final rawWings = List<String>.from(society['wings'] ?? []);
        final parsedWings = <String>[];
        for (var w in rawWings) {
          parsedWings.addAll(w.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
        }
        final wings = parsedWings.toSet().toList();
        _detectedSociety!['wings'] = wings; // update it so the UI uses the parsed wings

        if (wings.isNotEmpty && !_wingsContains(wings, _wingController.text)) {
          _wingController.text = wings.first;
        } else if (wings.isEmpty) {
          _wingController.clear();
        }
      });
    } else if (mounted) {
      setState(() {
        _detectedSociety = null;
      });
    }
  }

  bool _wingsContains(List<String> wings, String wing) {
    return wings.any((w) => w.toLowerCase() == wing.toLowerCase());
  }

  @override
  void dispose() {
    _societyCodeController.dispose();
    _flatController.dispose();
    _wingController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      
      final Map<String, dynamic> data = {
        'flat_no': _flatController.text.trim(),
        'is_owner': CurrentUser.isOwner,
      };
      
      if (_wingController.text.trim().isNotEmpty) {
        data['wing'] = _wingController.text.trim();
      }
      
      if (CurrentUser.societyId != null) {
        data['society_id'] = CurrentUser.societyId!;
      } else {
        data['society_code'] = _societyCodeController.text.trim();
      }
      
      await authService.createResidentProfile(data);
      
      // Update Current User
      await authService.fetchMe();
      
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSocietyPreFilled = CurrentUser.societyCode != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Complete Your Profile', style: TextStyle(color: Color(0xFF1F2937))),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF1F2937)),
          onPressed: () async {
            await ref.read(authServiceProvider).logout();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
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
                const Text(
                  'Almost there!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'We need a few more details to set up your resident dashboard.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasSocietyPreFilled) ...[
                        _buildLabel('Society Invite Code'),
                        _buildTextField(
                          controller: _societyCodeController,
                          hint: 'e.g. GVA-7K9X2',
                          prefix: Icons.qr_code_2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Society code is required' : null,
                        ),
                        const SizedBox(height: 16),
                      ] else if (_detectedSociety != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.apartment, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _detectedSociety!['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                    ),
                                    Text(
                                      'Code: ${_detectedSociety!['code']}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      _buildLabel('Flat / Unit Number'),
                      _buildTextField(
                        controller: _flatController,
                        hint: 'e.g. 101',
                        prefix: Icons.door_front_door_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Flat number is required' : null,
                      ),
                      const SizedBox(height: 16),

                      if (_detectedSociety != null && (_detectedSociety!['wings'] as List).isNotEmpty) ...[
                        _buildLabel('Wing'),
                        _buildDropdownField(
                          value: _detectedSociety!['wings'].contains(_wingController.text) 
                              ? _wingController.text 
                              : _detectedSociety!['wings'].first,
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
                        const SizedBox(height: 24),
                      ],

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
                              : const Text('Go to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
