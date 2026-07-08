import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/typography.dart';

void main() {
  runApp(const ProviderScope(child: SocietyApp()));
}

class SocietyApp extends ConsumerWidget {
  const SocietyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Society App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: AppTypography.textTheme,
      ),
      routerConfig: router,
    );
  }
}
