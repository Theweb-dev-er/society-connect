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

  /// List billing categories for the current society
  Future<List<dynamic>> listCategories() async {
    final response = await _dio.get('/workflow-items/categories/');
    final data = response.data as Map<String, dynamic>;
    return data['results'] as List<dynamic>? ?? [];
  }

  /// Create a new billing category
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    int? order,
  }) async {
    final response = await _dio.post('/workflow-items/categories/', data: {
      'name': name,
      if (description != null) 'description': description,
      if (order != null) 'order': order,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Update a billing category
  Future<Map<String, dynamic>> updateCategory(
    String id, {
    String? name,
    String? description,
    bool? isActive,
    int? order,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (isActive != null) data['is_active'] = isActive;
    if (order != null) data['order'] = order;
    final response = await _dio.patch('/workflow-items/categories/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Delete a billing category
  Future<void> deleteCategory(String id) async {
    await _dio.delete('/workflow-items/categories/$id/');
  }

  /// Get bill template for the current society
  Future<Map<String, dynamic>> getBillTemplate() async {
    final response = await _dio.get('/workflow-items/template/');
    return response.data as Map<String, dynamic>;
  }

  /// Update bill template
  Future<Map<String, dynamic>> updateBillTemplate({
    required Map<String, dynamic> rates,
    bool? isRecurring,
  }) async {
    final data = <String, dynamic>{
      'rates': rates,
    };
    if (isRecurring != null) data['is_recurring'] = isRecurring;
    final response = await _dio.patch('/workflow-items/template/', data: data);
    return response.data as Map<String, dynamic>;
  }
}
