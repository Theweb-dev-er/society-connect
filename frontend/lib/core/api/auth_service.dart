import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/current_user.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio;

  AuthService() : _dio = ApiClient().dio;

  /// Save tokens to SharedPreferences
  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', access);
    await prefs.setString('refreshToken', refresh);
  }

  /// Get tokens from SharedPreferences
  Future<Map<String, String?>> getSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'access': prefs.getString('accessToken'),
      'refresh': prefs.getString('refreshToken'),
    };
  }

  /// Clear tokens from SharedPreferences
  Future<void> clearSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }

  /// Logout user
  Future<void> logout() async {
    await clearSavedTokens();
    CurrentUser.clear();
  }

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _dio.post(
      '/auth/otp/send/',
      data: {'phone': phone},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Verify OTP and get JWT tokens
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final response = await _dio.post(
      '/auth/otp/verify/',
      data: {'phone': phone, 'code': code},
    );
    final data = response.data as Map<String, dynamic>;

    // Store tokens in CurrentUser
    if (data.containsKey('access') && data.containsKey('refresh')) {
      final access = data['access'] as String;
      final refresh = data['refresh'] as String;
      CurrentUser.accessToken = access;
      CurrentUser.refreshToken = refresh;
      await saveTokens(access, refresh);

      // Update user info if available
      if (data.containsKey('user')) {
        final user = data['user'] as Map<String, dynamic>;
        _updateCurrentUser(user, access, refresh);
      }
    }

    return data;
  }

  /// Fetch current user profile
  Future<Map<String, dynamic>> fetchMe() async {
    final response = await _dio.get('/auth/me/');
    final data = response.data as Map<String, dynamic>;
    _updateCurrentUser(data, CurrentUser.accessToken, CurrentUser.refreshToken);
    return data;
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    final refresh = CurrentUser.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('access')) {
        final access = data['access'] as String;
        CurrentUser.accessToken = access;
        await saveTokens(access, refresh);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Fetch society details by code
  Future<Map<String, dynamic>?> fetchSocietyByCode(String code) async {
    try {
      final response = await _dio.get('/societies/by-code/', queryParameters: {'code': code});
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Create resident profile
  Future<Map<String, dynamic>> createResidentProfile(Map<String, dynamic> data) async {
    final response = await _dio.post('/residents/register/', data: data);
    return response.data as Map<String, dynamic>;
  }

  void _updateCurrentUser(
    Map<String, dynamic> user,
    String? access,
    String? refresh,
  ) {
    final role = (user['role'] as String?) ?? 'resident';
    final isGuard = role == 'security_guard';

    CurrentUser.setUser(
      name: (user['name'] as String?) ?? 'User',
      role: role,
      phone: (user['phone'] as String?) ?? '',
      email: (user['email'] as String?) ?? '',
      wing: user['wing'] as String?,
      flatNo: user['flat_no'] as String?,
      owner: (user['is_owner'] as bool?) ?? false,
      admin: (user['is_admin'] as bool?) ?? false,
      maker: (user['is_maker'] as bool?) ?? false,
      checker: (user['is_checker'] as bool?) ?? false,
      approver: (user['is_approver'] as bool?) ?? false,
      securityGuard: isGuard,
      guardCanAddEntry: (user['guard_can_add_entry'] as bool?) ?? false,
      guardCanManagePreApproved: (user['guard_can_manage_pre_approved'] as bool?) ?? false,
      guardCanViewInsideList: (user['guard_can_view_inside_list'] as bool?) ?? false,
      guardCanViewGateLogs: (user['guard_can_view_gate_logs'] as bool?) ?? false,
      societyId: user['society']?.toString(),
      societyName: user['society_name'] as String?,
      societyCode: user['society_code'] as String?,
      societyWings: (user['society_wings'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      societyBhkTypes: (user['society_bhk_types'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      accessToken: access,
      refreshToken: refresh,
    );
  }
}
