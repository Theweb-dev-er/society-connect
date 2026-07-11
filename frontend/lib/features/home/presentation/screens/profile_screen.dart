import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/router/app_routes.dart';
import 'package:society_app/core/theme/colors.dart';
import 'package:society_app/features/auth/data/models/current_user.dart';
import 'package:society_app/services/notification_service.dart';
import 'package:society_app/core/api/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            title: const Text(
              'My Profile',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
                onPressed: () => _showEditProfileSheet(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF3B82F6),
                            child: Text(
                              CurrentUser.name.isNotEmpty
                                  ? CurrentUser.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        CurrentUser.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        CurrentUser.phone.isNotEmpty ? CurrentUser.phone : 'No Phone Number',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          CurrentUser.flatNo != null
                              ? '${CurrentUser.flatNo!.startsWith("Flat") ? "" : "Flat "}${CurrentUser.flatNo} • ${CurrentUser.societyName ?? "Sunshine Residency"}'
                              : (CurrentUser.role == 'security_guard'
                                  ? 'Guard • ${CurrentUser.societyName ?? "Sunshine Residency"}'
                                  : 'Resident • ${CurrentUser.societyName ?? "Sunshine Residency"}'),
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Account Sections
                _buildSectionHeader('Account Information'),
                _buildProfileItem(
                  Icons.person_outline,
                  'Personal Details',
                  'Name: ${CurrentUser.name}${CurrentUser.email.isNotEmpty ? " • Email: ${CurrentUser.email}" : ""}',
                ),
                _buildProfileItem(
                  Icons.apartment_outlined,
                  'Flat Information',
                  CurrentUser.flatNo != null
                      ? 'Flat Number: ${CurrentUser.flatNo!.replaceAll("Flat ", "")} • ${CurrentUser.societyName ?? "Sunshine Residency"}'
                      : 'Role: ${CurrentUser.role == "security_guard" ? "Security Guard" : "Resident"}',
                ),
                _buildProfileItem(Icons.family_restroom_outlined, 'Family Members', '3 Members added'),
                _buildProfileItem(Icons.directions_car_outlined, 'My Vehicles', '2 Vehicles registered'),


                const SizedBox(height: 8),

                _buildSectionHeader('Preferences'),
                _buildProfileItem(Icons.notifications_outlined, 'Notifications', 'Push, SMS, Email'),
                _buildProfileItem(Icons.lock_outline, 'Privacy & Security', 'Password, 2FA'),
                _buildProfileItem(Icons.language_outlined, 'App Language', 'English'),

                const SizedBox(height: 8),

                _buildSectionHeader('Support'),
                _buildProfileItem(Icons.help_outline, 'Help Center', 'FAQs, Contact Support'),
                _buildProfileItem(Icons.description_outlined, 'Terms & Policies', 'Privacy Policy, TOS'),

                const SizedBox(height: 24),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await NotificationService().deleteDeviceToken();
                        await AuthService().logout();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                  ),
                ),
                
                const SizedBox(height: 12),
                const Text(
                  'App Version 1.0.2 (Build 42)',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4B5563), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD1D5DB)),
        onTap: () {},
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField('Full Name', CurrentUser.name),
            const SizedBox(height: 16),
            _buildTextField('Email Address', CurrentUser.email),
            const SizedBox(height: 16),
            _buildTextField('Phone Number', CurrentUser.phone),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
      ],
    );
  }
}
