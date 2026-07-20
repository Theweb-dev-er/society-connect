import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<dynamic> addResidentManually(String name, String phone, String wing, String flatNo, bool isOwner, {String? bhkType}) async {
    final response = await _dio.post('/residents/admin-add/', data: {
      'name': name,
      'phone': phone,
      'wing': wing,
      'flat_no': flatNo,
      'is_owner': isOwner,
      if (bhkType != null && bhkType.isNotEmpty) 'bhk_type': bhkType,
    });
    return response.data;
  }

  Future<dynamic> importResidentsCSV(PlatformFile file) async {
    final formData = FormData.fromMap({
      'file': file.bytes != null
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : await MultipartFile.fromFile(file.path!, filename: file.name),
    });
    final response = await _dio.post('/residents/admin-import/', data: formData);
    return response.data;
  }
}
