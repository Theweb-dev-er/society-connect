import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';


class ExpectedVisitorsScreen extends StatefulWidget {
  const ExpectedVisitorsScreen({super.key});

  @override
  State<ExpectedVisitorsScreen> createState() => _ExpectedVisitorsScreenState();
}

class _ExpectedVisitorsScreenState extends State<ExpectedVisitorsScreen> {
  String? _selectedVisitorType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  final List<String> _visitorTypes = ['Guest', 'Delivery', 'Maid', 'Vendor', 'Other'];

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Expected Visitors',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pre-Approve Form Card
                Container(
                  padding: const EdgeInsets.all(24),
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
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_outlined,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Pre-Approve Visitor',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildLabel('Visitor Name'),
                      _buildTextField('Enter visitor name'),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Number of People'),
                      _buildTextField('e.g., 2', keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Visitor Type'),
                      _buildDropdownField('Select visitor type'),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Expected Date'),
                      _buildDateField(context, 'dd/mm/yyyy'),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Expected Time'),
                      _buildTimeField(context, '--:--'),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            _showQRDialog(context, 'Rohan Mehta', 'Guest', 'May 19, 2026', '6:00 PM');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6EE7B7), // Mint green from design
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Pre-Approve Visitor',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Upcoming Visitors Header
                const Text(
                  'Upcoming Visitors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Upcoming Visitors List
                _buildUpcomingCard(
                  context,
                  name: 'Rohan Mehta',
                  type: 'Guest',
                  date: 'May 19, 2026',
                  time: '6:00 PM',
                ),
                const SizedBox(height: 12),
                _buildUpcomingCard(
                  context,
                  name: 'Amazon Delivery',
                  type: 'Delivery',
                  date: 'May 18, 2026',
                  time: '2:00 PM - 5:00 PM',
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {TextInputType? keyboardType}) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedVisitorType,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
          items: _visitorTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedVisitorType = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, String hint) {
    final displayDate = _selectedDate != null 
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
        : '';
        
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: displayDate),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF9CA3AF), size: 18),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTimeField(BuildContext context, String hint) {
    final displayTime = _selectedTime?.format(context) ?? '';
    
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: displayTime),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
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
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, {
    required String name,
    required String type,
    required String date,
    required String time,
  }) {
    return InkWell(
      onTap: () => _showQRDialog(context, name, type, date, time),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Pre-Approved',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            type,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showQRDialog(BuildContext context, String name, String type, String date, String time) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 48),
              const SizedBox(height: 16),
              const Text(
                'Visitor Pre-Approved',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this pass with $name',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: QrImageView(
                  data: 'VISITOR_$name',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Pass'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
