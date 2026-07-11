import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/core/api/auth_service.dart';
import 'package:society_app/core/router/app_routes.dart';
import 'package:society_app/features/auth/data/models/current_user.dart';
import 'package:society_app/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _controller.forward();
    _initApp();
  }

  void _initApp() async {
    final startTime = DateTime.now();
    String targetRoute = AppRoutes.login;

    try {
      final authService = AuthService();
      final tokens = await authService.getSavedTokens();
      final access = tokens['access'];
      final refresh = tokens['refresh'];

      if (access != null && access.isNotEmpty) {
        CurrentUser.accessToken = access;
        CurrentUser.refreshToken = refresh;

        String? role;

        try {
          // Try fetching user with the saved access token
          final userData = await authService.fetchMe();
          role = userData['role'] as String?;
        } catch (fetchErr) {
          debugPrint('[Splash] fetchMe failed, attempting token refresh: $fetchErr');
          // Access token may be expired — try to refresh it
          final refreshed = await authService.refreshToken();
          if (refreshed) {
            try {
              final userData = await authService.fetchMe();
              role = userData['role'] as String?;
            } catch (e2) {
              debugPrint('[Splash] fetchMe still failed after refresh: $e2');
            }
          }
        }

        if (role != null) {
          // Session confirmed valid — route to dashboard
          if (role == 'security_guard') {
            targetRoute = AppRoutes.securityDashboard;
          } else {
            targetRoute = AppRoutes.dashboard;
          }
          // Only initialize FCM after session is confirmed
          NotificationService().initialize();
        } else {
          // Tokens invalid — clear them so user logs in fresh
          await authService.clearSavedTokens();
        }
      }
    } catch (e) {
      debugPrint('[Splash] Session restore failed: $e');
    }

    final elapsed = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(milliseconds: 1500) - elapsed;

    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

    if (mounted) {
      context.go(targetRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  Text(
                    'SmartSociety',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Elevating Community Living',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
