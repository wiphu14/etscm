import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  // ============================================
  // Login - Web/Admin
  // ============================================
  
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String role,
    int? villageId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        data: {
          'username': username,
          'password': password,
          'role': role,
          if (villageId != null) 'village_id': villageId,
        },
      );

      debugPrint('🟡 Raw API Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // รองรับหลายรูปแบบ response จาก Backend
        // แบบ 1: {success, data: {user, token}}
        // แบบ 2: {success, user, token}
        // แบบ 3: {success, user} (ไม่มี token)
        
        final data = response.data['data'];
        final user = data?['user'] ?? response.data['user'];
        final token = data?['token'] ?? response.data['token'];
        final refreshToken = data?['refresh_token'] ?? response.data['refresh_token'];

        return {
          'success': true,
          'user': user,
          'token': token,
          'refresh_token': refreshToken,
          'message': response.data['message'] ?? 'เข้าสู่ระบบสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 Login Repository Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Login - Sunmi Device
  // ============================================
  
  Future<Map<String, dynamic>> loginSunmi({
    required String username,
    required String password,
    required String deviceUuid,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.sunmiLogin,
        data: {
          'username': username,
          'password': password,
          'device_uuid': deviceUuid,
        },
      );

      debugPrint('🟡 Raw Sunmi API Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final user = data?['user'] ?? response.data['user'];
        final token = data?['token'] ?? response.data['token'];
        final village = data?['village'] ?? response.data['village'];

        return {
          'success': true,
          'user': user,
          'token': token,
          'village': village,
          'message': response.data['message'] ?? 'เข้าสู่ระบบสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 LoginSunmi Repository Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Logout
  // ============================================
  
  Future<void> logout() async {
    await _apiService.logout();
  }

  // ============================================
  // User Profile
  // ============================================
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiService.get('${ApiConfig.auth}/me.php');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.auth}/update-profile.php',
        data: profileData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'อัปเดตโปรไฟล์สำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'อัปเดตโปรไฟล์ไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.auth}/change-password.php',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'เปลี่ยนรหัสผ่านสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'เปลี่ยนรหัสผ่านไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Connection Test
  // ============================================
  
  Future<Map<String, dynamic>> testConnection() async {
    return await _apiService.testConnection();
  }
}