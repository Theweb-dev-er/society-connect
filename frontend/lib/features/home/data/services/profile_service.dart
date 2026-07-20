import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../models/family_member.dart';
import '../models/vehicle.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  // Profile (Personal Details)
  Future<void> updatePersonalDetails(String name, String email) async {
    try {
      await _apiClient.dio.patch('/auth/me/', data: {
        'name': name,
        'email': email,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update details');
    }
  }

  // Family Members
  Future<List<FamilyMember>> getFamilyMembers() async {
    try {
      final response = await _apiClient.dio.get('/residents/family-members/');
      final results = response.data['results'] as List;
      return results.map((e) => FamilyMember.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to fetch family members');
    }
  }

  Future<FamilyMember> addFamilyMember(String name, String phone, String relationToPrimary) async {
    try {
      final response = await _apiClient.dio.post('/residents/family-members/', data: {
        'name': name,
        'phone': phone,
        'relation_to_primary': relationToPrimary,
      });
      return FamilyMember.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to add family member');
    }
  }

  Future<void> removeFamilyMember(String id) async {
    try {
      await _apiClient.dio.delete('/residents/family-members/$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to remove family member');
    }
  }

  // Vehicles
  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _apiClient.dio.get('/residents/vehicles/');
      final results = response.data['results'] as List;
      return results.map((e) => Vehicle.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to fetch vehicles');
    }
  }

  Future<Vehicle> addVehicle(String vehicleType, String vehicleNumber, String makeModel) async {
    try {
      final response = await _apiClient.dio.post('/residents/vehicles/', data: {
        'vehicle_type': vehicleType,
        'vehicle_number': vehicleNumber,
        'make_model': makeModel,
      });
      return Vehicle.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to add vehicle');
    }
  }

  Future<void> removeVehicle(String id) async {
    try {
      await _apiClient.dio.delete('/residents/vehicles/$id/');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to remove vehicle');
    }
  }
}
