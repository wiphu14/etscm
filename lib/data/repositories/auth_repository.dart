import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

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
      final response = await _apiService.post(
        '/auth/login.php',
        data: {
          'username': username,
          'password': password,
          'role': role,
          if (villageId != null) 'village_id': villageId,
        },
      );

      // response เป็น Dio Response ต้องใช้ .data
      final responseData = response.data;
      
      debugPrint('🟡 Raw API Response: $responseData');

      if (responseData != null && responseData['success'] == true) {
        // API ส่งมาใน format: { success, message, data: {...}, token }
        return {
          'success': true,
          'user': responseData['data'],  // ส่ง data กลับเป็น user
          'data': responseData['data'],  // ส่ง data กลับด้วย
          'token': responseData['token'] ?? responseData['data']?['token'],
          'refresh_token': responseData['refresh_token'],
          'message': responseData['message'] ?? 'เข้าสู่ระบบสำเร็จ',
        };
      } else {
        return {
          'success': false,
          'message': responseData?['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ',
        };
      }
    } catch (e) {
      debugPrint('🔴 Login Repository Error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Logout
  Future<bool> logout() async {
    try {
      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
    }
  }

  /// Refresh Token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiService.post(
        '/auth/refresh.php',
        data: {'refresh_token': refreshToken},
      );

      final responseData = response.data;

      if (responseData != null && responseData['success'] == true) {
        return {
          'success': true,
          'token': responseData['token'],
          'refresh_token': responseData['refresh_token'],
        };
      } else {
        return {
          'success': false,
          'message': responseData?['message'] ?? 'ไม่สามารถต่ออายุ Token ได้',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Change Password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/change-password.php',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      final responseData = response.data;

      if (responseData != null && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'เปลี่ยนรหัสผ่านสำเร็จ',
        };
      } else {
        return {
          'success': false,
          'message': responseData?['message'] ?? 'เปลี่ยนรหัสผ่านไม่สำเร็จ',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get User Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get('/auth/profile.php');

      final responseData = response.data;

      if (responseData != null && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData?['message'] ?? 'ไม่สามารถดึงข้อมูลผู้ใช้ได้',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}