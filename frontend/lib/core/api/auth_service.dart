import 'package:dio/dio.dart';
import '../../features/auth/data/models/current_user.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio;

  AuthService() : _dio = ApiClient().dio;

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
      CurrentUser.accessToken = data['access'] as String;
      CurrentUser.refreshToken = data['refresh'] as String;

      // Update user info if available
      if (data.containsKey('user')) {
        final user = data['user'] as Map<String, dynamic>;
        _updateCurrentUser(user, data['access'] as String, data['refresh'] as String);
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
        CurrentUser.accessToken = data['access'] as String;
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
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
      owner: false,
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
      accessToken: access,
      refreshToken: refresh,
    );
  }
}
