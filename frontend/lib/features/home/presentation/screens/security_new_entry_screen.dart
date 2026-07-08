import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecurityNewEntryScreen extends StatefulWidget {
  const SecurityNewEntryScreen({super.key});

  @override
  State<SecurityNewEntryScreen> createState() => _SecurityNewEntryScreenState();
}

class _SecurityNewEntryScreenState extends State<SecurityNewEntryScreen> {
  String? _selectedVisitorType;
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
          'New Entry',
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
            _buildSectionTitle('Visitor Details'),
            const SizedBox(height: 16),
            _buildTextField('Mobile Number', Icons.phone),
            const SizedBox(height: 16),
            _buildTextField('Full Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField('Number of People', Icons.group, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildDropdownField('Visitor Type (e.g. Delivery, Guest)', Icons.category),
            const SizedBox(height: 32),
            _buildSectionTitle('Visit Details'),
            const SizedBox(height: 16),
            _buildTextField('Block / Flat Number', Icons.apartment),
            const SizedBox(height: 16),
            _buildTextField('Vehicle Number (Optional)', Icons.directions_car),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visitor Logged Successfully')),
                  );
                  context.pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Log Entry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedVisitorType,
          hint: Row(
            children: [
              Icon(icon, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 12),
              Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            ],
          ),
          items: _visitorTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedVisitorType = value;
              });
            }
          },
        ),
      ),
    );
  }
}
