import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/typography.dart';

const firebaseWebOptions = FirebaseOptions(
  apiKey: "AIzaSyBQmwUNts7Jhv-pZ31PTp0v2JMuWPtDtjw",
  authDomain: "societyconnect-171d7.firebaseapp.com",
  projectId: "societyconnect-171d7",
  storageBucket: "societyconnect-171d7.firebasestorage.app",
  messagingSenderId: "373614264581",
  appId: "1:373614264581:web:c19ad0998a1f41aec7776c",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: firebaseWebOptions);
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
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
