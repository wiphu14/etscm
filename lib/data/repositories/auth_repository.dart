import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  /// Login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String role,
    int? villageId,
  }) async {
    try {
      final response = await _apiService.login(
        username: username,
        password: password,
        role: role,
        villageId: villageId,
      );

      return {
        'success': true,
        'user': response['user'],
        'token': response['token'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Logout
  Future<void> logout() async {
    await _apiService.logout();
  }

  /// Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiService.get('${ApiConfig.auth}/me');
      return response.data;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
}