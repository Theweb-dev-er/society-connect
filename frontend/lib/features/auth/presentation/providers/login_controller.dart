import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_state.dart';

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> login(String email, String password) async {
    // Reset error and set loading state
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Basic mock validation logic
      if (email.isNotEmpty && password.length >= 6) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid credentials provided');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(() {
  return LoginController();
});
