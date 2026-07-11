import 'package:dio/dio.dart';
import 'api_client.dart';

class VisitorService {
  final Dio _dio;

  VisitorService() : _dio = ApiClient().dio;

  /// List pre-approved visitors with optional filters
  Future<List<dynamic>> listVisitors({String? status, String? type}) async {
    final response = await _dio.get(
      '/visitors/',
      queryParameters: {
        if (status != null) 'status': status,
        if (type != null) 'type': type,
      },
    );
    // Handle cursor pagination response
    final data = response.data as Map<String, dynamic>;
    return data['results'] as List<dynamic>? ?? [];
  }

  /// Create a pre-approved visitor
  Future<Map<String, dynamic>> createVisitor({
    required String name,
    required String type,
    required String flat,
    String? phone,
    String? vehicleNumber,
    int? peopleCount,
    String? expectedTime,
  }) async {
    final response = await _dio.post('/visitors/', data: {
      'name': name,
      'type': type,
      'flat': flat,
      if (phone != null) 'phone': phone,
      if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
      if (peopleCount != null) 'people_count': peopleCount,
      if (expectedTime != null) 'expected_time': expectedTime,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Mark visitor as entered
  Future<Map<String, dynamic>> markEntered(String visitorId) async {
    final response = await _dio.post('/visitors/$visitorId/enter/');
    return response.data as Map<String, dynamic>;
  }

  /// Mark visitor as exited
  Future<Map<String, dynamic>> markExited(String visitorId) async {
    final response = await _dio.post('/visitors/$visitorId/exit/');
    return response.data as Map<String, dynamic>;
  }

  /// List visitors currently inside
  Future<List<dynamic>> listInside() async {
    final response = await _dio.get('/visitors/inside/');
    return response.data as List<dynamic>;
  }

  /// List gate logs
  Future<List<dynamic>> listGateLogs() async {
    final response = await _dio.get('/visitors/gate-logs/');
    final data = response.data as Map<String, dynamic>;
    return data['results'] as List<dynamic>? ?? [];
  }

  /// Get specific visitor details
  Future<Map<String, dynamic>> getVisitor(String visitorId) async {
    final response = await _dio.get('/visitors/$visitorId/');
    return response.data as Map<String, dynamic>;
  }
}
