import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecretaryResidentDirectoryScreen extends StatefulWidget {
  const SecretaryResidentDirectoryScreen({super.key});

  @override
  State<SecretaryResidentDirectoryScreen> createState() => _SecretaryResidentDirectoryScreenState();
}

class _SecretaryResidentDirectoryScreenState extends State<SecretaryResidentDirectoryScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allResidents = [
    {
      'name': 'Aman Gupta',
      'flat': 'Flat 402 - Block A',
      'phone': '+91 98765 43210',
      'role': 'Owner',
      'avatarColor': const Color(0xFFDBEAFE),
      'textColor': const Color(0xFF1E40AF),
    },
    {
      'name': 'Rajesh Kumar',
      'flat': 'Flat 304 - Block A',
      'phone': '+91 99887 76655',
      'role': 'Tenant',
      'avatarColor': const Color(0xFFFEF3C7),
      'textColor': const Color(0xFF92400E),
    },
    {
      'name': 'Rohan Mehta',
      'flat': 'Flat 105 - Block B',
      'phone': '+91 88776 65544',
      'role': 'Owner',
      'avatarColor': const Color(0xFFD1FAE5),
      'textColor': const Color(0xFF065F46),
    },
    {
      'name': 'Priya Sharma',
      'flat': 'Flat 202 - Block B',
      'phone': '+91 77665 54433',
      'role': 'Tenant',
      'avatarColor': const Color(0xFFFCE7F3),
      'textColor': const Color(0xFF9D174D),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredResidents = _allResidents.where((resident) {
      final query = _searchQuery.toLowerCase();
      final name = (resident['name'] as String).toLowerCase();
      final flat = (resident['flat'] as String).toLowerCase();
      return name.contains(query) || flat.contains(query);
    }).toList();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                    onPressed: () => context.pop(),
                  ),
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or flat...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : const Text(
                    'Resident Directory',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            centerTitle: false,
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF1F2937)),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
            ],
          ),
          body: filteredResidents.isEmpty
              ? Center(
                  child: Text(
                    'No residents found for "$_searchQuery"',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredResidents.length,
                  itemBuilder: (context, index) {
                    final res = filteredResidents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildResidentCard(
                        name: res['name'],
                        flat: res['flat'],
                        phone: res['phone'],
                        role: res['role'],
                        avatarColor: res['avatarColor'],
                        textColor: res['textColor'],
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddResidentSheet(context),
            backgroundColor: const Color(0xFF10B981),
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Add Resident',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResidentCard({
    required String name,
    required String flat,
    required String phone,
    required String role,
    required Color avatarColor,
    required Color textColor,
  }) {
    final initials = name.split(' ').map((e) => e[0]).take(2).join('');
    
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role == 'Owner' ? const Color(0xFFEFF6FF) : const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: role == 'Owner' ? const Color(0xFF3B82F6) : const Color(0xFFA855F7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  flat,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResidentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 460),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  'Add New Resident',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildLabel('Full Name'),
                _buildTextField('e.g., Jane Doe'),
                const SizedBox(height: 16),
                
                _buildLabel('Phone Number'),
                _buildTextField('+91 xxxxx xxxxx', isPhone: true),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Block'),
                          _buildTextField('e.g., A'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Flat Number'),
                          _buildTextField('e.g., 402'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildLabel('Role'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'Owner',
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
                      items: ['Owner', 'Tenant']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {},
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Resident', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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

  Widget _buildTextField(String hint, {bool isPhone = false}) {
    return TextField(
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
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
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }
}
