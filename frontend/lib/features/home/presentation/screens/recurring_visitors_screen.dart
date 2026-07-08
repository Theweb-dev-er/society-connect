import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecurringVisitorsScreen extends StatelessWidget {
  const RecurringVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Recurring Visitors',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Manage regular visitors with automatic entry approval during scheduled times',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showAddVisitorSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED), // Purple
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Recurring Visitor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildRecurringCard(
                name: 'Sunita Devi',
                role: 'Maid',
                isActive: true,
                activeDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
                allowedTime: '8:00 AM - 11:00 AM',
                avatarIcon: Icons.face_3,
                avatarBgColor: const Color(0xFFF3E8FF),
                avatarIconColor: const Color(0xFFD97706),
              ),
              const SizedBox(height: 16),
              _buildRecurringCard(
                name: 'Rajesh Kumar',
                role: 'Driver',
                isActive: true,
                activeDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                allowedTime: '7:00 AM - 10:00 PM',
                avatarIcon: Icons.face,
                avatarBgColor: const Color(0xFFF3E8FF),
                avatarIconColor: const Color(0xFFD97706),
              ),
              const SizedBox(height: 16),
              _buildRecurringCard(
                name: 'Tiffin Service',
                role: 'Tiffin Vendor',
                isActive: false,
                activeDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                allowedTime: '12:00 PM - 2:00 PM',
                avatarIcon: Icons.bento,
                avatarBgColor: const Color(0xFFF3E8FF),
                avatarIconColor: const Color(0xFFD97706),
              ),
            ],
          ),
        ),
        ),
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringCard({
    required String name,
    required String role,
    required bool isActive,
    required List<String> activeDays,
    required String allowedTime,
    required IconData avatarIcon,
    required Color avatarBgColor,
    required Color avatarIconColor,
  }) {
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(avatarIcon, color: avatarIconColor, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        isActive ? 'Active' : 'Disabled',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isActive,
                          onChanged: (val) {},
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF10B981),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFD1D5DB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              const Text(
                'Allowed Days',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: daysOfWeek.map((day) {
              final isDaySelected = activeDays.contains(day);

              Color getBgColor() {
                if (!isDaySelected) return const Color(0xFFF3F4F6); // gray
                if (!isActive) return const Color(0xFFC4B5FD); // lighter purple
                return const Color(0xFF7C3AED); // purple
              }

              Color getTextColor() {
                if (!isDaySelected) return const Color(0xFF9CA3AF);
                return Colors.white;
              }

              return Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: getBgColor(),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: getTextColor(),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              const Text(
                'Allowed Time',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              allowedTime,
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF8F9FA),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Edit Schedule',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVisitorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 460),
      builder: (context) => const AddRecurringVisitorSheet(),
    );
  }
}

class AddRecurringVisitorSheet extends StatefulWidget {
  const AddRecurringVisitorSheet({super.key});

  @override
  State<AddRecurringVisitorSheet> createState() => _AddRecurringVisitorSheetState();
}

class _AddRecurringVisitorSheetState extends State<AddRecurringVisitorSheet> {
  final List<String> _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Set<String> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Recurring Visitor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildLabel('Visitor Name'),
            _buildTextField('Enter visitor name'),
            const SizedBox(height: 16),
            
            _buildLabel('Role/Type'),
            _buildTextField('e.g., Maid, Driver, Milkman'),
            const SizedBox(height: 16),
            
            _buildLabel('Allowed Days'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Start Time'),
                      _buildTimeField('08:00 AM'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('End Time'),
                      _buildTimeField('12:00 PM'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED), // Purple
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Visitor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTimeField(String hint) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
        prefixIcon: const Icon(Icons.access_time, color: Color(0xFF9CA3AF), size: 18),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
      ),
    );
  }
}
