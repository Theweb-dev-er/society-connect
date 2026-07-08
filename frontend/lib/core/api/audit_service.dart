import 'package:dio/dio.dart';
import 'api_client.dart';

class AuditService {
  final Dio _dio;

  AuditService() : _dio = ApiClient().dio;

  /// List audit logs with optional filters
  Future<List<dynamic>> listAuditLogs({String? role, String? action}) async {
    final response = await _dio.get(
      '/audit-logs/',
      queryParameters: {
        if (role != null) 'role': role,
        if (action != null) 'action': action,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['results'] as List<dynamic>? ?? [];
  }
}
