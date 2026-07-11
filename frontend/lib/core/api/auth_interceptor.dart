import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import 'auth_service.dart';
import 'api_client.dart';
import '../../features/auth/data/models/current_user.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = CurrentUser.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Prevent infinite loops if refreshing token itself fails
      if (err.requestOptions.path.contains('/auth/token/refresh/')) {
        handler.next(err);
        return;
      }

      try {
        final success = await AuthService().refreshToken();
        if (success) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${CurrentUser.accessToken}';
          
          // Retry the request with the new token using a clean Dio instance to avoid interceptor recursion
          final retryDio = Dio();
          final response = await retryDio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // Fall through to error handling if retry fails
      }

      // If refresh failed or was not successful, log out and redirect to login page
      await AuthService().logout();
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.go('/login');
      }
    }
    handler.next(err);
  }
}

