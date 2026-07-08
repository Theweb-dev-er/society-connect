import 'package:dio/dio.dart';
import 'api_client.dart';

class BillingService {
  final Dio _dio;

  BillingService() : _dio = ApiClient().dio;

  /// List workflow items (expenses/bills) with optional filters
  Future<List<dynamic>> listWorkflowItems({String? stage, String? type}) async {
    final response = await _dio.get(
      '/workflow-items/',
      queryParameters: {
        if (stage != null) 'stage': stage,
        if (type != null) 'type': type,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['results'] as List<dynamic>? ?? [];
  }

  /// Create a new expense or bill
  Future<Map<String, dynamic>> createWorkflowItem({
    required String type,
    required String title,
    required double amount,
    String? description,
    Map<String, dynamic>? payload,
  }) async {
    final response = await _dio.post('/workflow-items/', data: {
      'type': type,
      'title': title,
      'amount': amount,
      if (description != null) 'description': description,
      if (payload != null) 'payload': payload,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Perform workflow action: submit, check, approve, reject
  Future<Map<String, dynamic>> performAction(
    String itemId, {
    required String action,
    String? comment,
  }) async {
    final response = await _dio.post('/workflow-items/$itemId/actions/', data: {
      'action': action,
      if (comment != null) 'comment': comment,
    });
    return response.data as Map<String, dynamic>;
  }
}
