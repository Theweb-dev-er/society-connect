import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/visitor_service.dart';

class SecurityNewEntryScreen extends StatefulWidget {
  const SecurityNewEntryScreen({super.key});

  @override
  State<SecurityNewEntryScreen> createState() => _SecurityNewEntryScreenState();
}

class _SecurityNewEntryScreenState extends State<SecurityNewEntryScreen> {
  String? _selectedVisitorType;
  final List<String> _visitorTypes = ['Guest', 'Delivery', 'Maid', 'Vendor', 'Other'];

  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _peopleController = TextEditingController();
  final _flatController = TextEditingController();
  final _vehicleController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _peopleController.dispose();
    _flatController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

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
            _buildTextField('Mobile Number', Icons.phone, _mobileController, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField('Full Name', Icons.person, _nameController),
            const SizedBox(height: 16),
            _buildTextField('Number of People', Icons.group, _peopleController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildDropdownField('Visitor Type (e.g. Delivery, Guest)', Icons.category),
            const SizedBox(height: 32),
            _buildSectionTitle('Visit Details'),
            const SizedBox(height: 16),
            _buildTextField('Block / Flat Number', Icons.apartment, _flatController),
            const SizedBox(height: 16),
            _buildTextField('Vehicle Number (Optional)', Icons.directions_car, _vehicleController),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _submitting ? null : () async {
                  final name = _nameController.text.trim();
                  final mobile = _mobileController.text.trim();
                  final flat = _flatController.text.trim();
                  final type = _selectedVisitorType;
                  final people = _peopleController.text.trim();
                  final vehicle = _vehicleController.text.trim();

                  if (name.isEmpty || flat.isEmpty || type == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in Name, Flat, and Visitor Type.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() => _submitting = true);

                  try {
                    // Map to backend choices: "guest", "delivery", "service"
                    String backendType = "guest";
                    if (type == 'Delivery') {
                      backendType = 'delivery';
                    } else if (type == 'Maid' || type == 'Vendor' || type == 'Other') {
                      backendType = 'service';
                    }

                    await VisitorService().createVisitor(
                      name: name,
                      type: backendType,
                      flat: flat,
                      phone: mobile.isNotEmpty ? mobile : null,
                      vehicleNumber: vehicle.isNotEmpty ? vehicle : null,
                      peopleCount: int.tryParse(people) ?? 1,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Visitor Logged Successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      context.pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to log visitor: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _submitting = false);
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
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

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
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

