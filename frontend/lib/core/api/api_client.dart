import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000';

  late final Dio _dio;

  Dio get dio => _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print('[API] $message');
}
