import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/theme/colors.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Scaffold(
            body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: AppColors.primary.withOpacity(0.1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppColors.primary),
                label: 'Visitors',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_laundry_service_outlined),
                selectedIcon: Icon(Icons.local_laundry_service, color: AppColors.primary),
                label: 'Services',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.primary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
          ),
        ),
      ),
    );
  }
}
