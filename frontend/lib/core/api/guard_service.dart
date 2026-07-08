import 'package:dio/dio.dart';
import 'api_client.dart';

class GuardService {
  final Dio _dio;

  GuardService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<dynamic>> listGuards() async {
    final response = await _dio.get('/guards/');
    final results = response.data['results'] as List<dynamic>? ?? [];
    return results;
  }

  Future<dynamic> createGuard({
    required String name,
    required String phone,
    String? email,
    String? gate,
    String? shift,
    bool canAddEntry = true,
    bool canManagePreApproved = true,
    bool canViewInsideList = true,
    bool canViewGateLogs = true,
  }) async {
    final response = await _dio.post('/guards/', data: {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (gate != null && gate.isNotEmpty) 'gate': gate,
      if (shift != null && shift.isNotEmpty) 'shift': shift.toLowerCase(),
      'can_add_entry': canAddEntry,
      'can_manage_pre_approved': canManagePreApproved,
      'can_view_inside_list': canViewInsideList,
      'can_view_gate_logs': canViewGateLogs,
    });
    return response.data;
  }

  Future<dynamic> updateAccess(String id, {
    bool? canAddEntry,
    bool? canManagePreApproved,
    bool? canViewInsideList,
    bool? canViewGateLogs,
  }) async {
    final data = <String, dynamic>{};
    if (canAddEntry != null) data['can_add_entry'] = canAddEntry;
    if (canManagePreApproved != null) data['can_manage_pre_approved'] = canManagePreApproved;
    if (canViewInsideList != null) data['can_view_inside_list'] = canViewInsideList;
    if (canViewGateLogs != null) data['can_view_gate_logs'] = canViewGateLogs;

    final response = await _dio.patch('/guards/$id/access/', data: data);
    return response.data;
  }

  Future<dynamic> toggleActive(String id) async {
    final response = await _dio.post('/guards/$id/toggle/');
    return response.data;
  }
}
