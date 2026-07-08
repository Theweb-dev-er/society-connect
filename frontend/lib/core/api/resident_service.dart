import 'package:dio/dio.dart';
import 'api_client.dart';

class ResidentService {
  final Dio _dio;

  ResidentService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<dynamic>> listResidents() async {
    final response = await _dio.get('/residents/');
    final results = response.data['results'] as List<dynamic>? ?? [];
    return results;
  }

  Future<dynamic> updateRoles(String id, {
    bool? isAdmin,
    bool? isMaker,
    bool? isChecker,
    bool? isApprover,
  }) async {
    final data = <String, dynamic>{};
    if (isAdmin != null) data['is_admin'] = isAdmin;
    if (isMaker != null) data['is_maker'] = isMaker;
    if (isChecker != null) data['is_checker'] = isChecker;
    if (isApprover != null) data['is_approver'] = isApprover;

    final response = await _dio.patch('/residents/$id/roles/', data: data);
    return response.data;
  }

  Future<dynamic> transferAdmin({
    required String fromResidentId,
    required String toResidentId,
    String reason = '',
  }) async {
    final response = await _dio.post('/residents/transfer/', data: {
      'from_resident_id': fromResidentId,
      'to_resident_id': toResidentId,
      'reason': reason,
    });
    return response.data;
  }
}
