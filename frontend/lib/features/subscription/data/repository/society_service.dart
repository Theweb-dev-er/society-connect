import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class SocietyService {
  final Dio _dio;

  SocietyService() : _dio = ApiClient().dio;

  Future<bool> checkPhoneExists(String phone) async {
    try {
      final response = await _dio.post(
        '/societies/check-phone/',
        data: {'phone': phone},
      );
      return response.data['exists'] as bool? ?? false;
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Failed to check phone number.';
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<Map<String, dynamic>> registerSociety(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/societies/register/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Failed to register society. Please try again.';
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
}
