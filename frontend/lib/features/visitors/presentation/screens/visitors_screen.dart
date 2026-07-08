import 'package:flutter/material.dart';
import 'package:society_app/core/theme/colors.dart';

class VisitorsScreen extends StatelessWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: AppColors.primaryLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Visitor Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Pre-Approve', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
