import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

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
              'Home Services',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.construction_rounded,
                      size: 48,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Coming Soon!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We\'re working hard to bring you home services like cleaning, plumbing, electrical, and more.\n\nStay tuned — it\'s launching very soon!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_outlined, size: 16, color: Color(0xFF3B82F6)),
                        SizedBox(width: 8),
                        Text(
                          'We\'ll notify you when it\'s ready',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
