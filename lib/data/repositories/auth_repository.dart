import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  /// Login
  /// รองรับทั้ง admin และ user login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? role,
    int? villageId,
  }) async {
    try {
      debugPrint('🔵 AuthRepository.login() เริ่มทำงาน...');
      debugPrint('🔵 Username: $username');
      debugPrint('🔵 Role: ${role ?? "auto-detect"}');
      debugPrint('🔵 Village ID: $villageId');
      
      final response = await _apiService.post(
        '/auth/login.php',
        data: {
          'username': username,
          'password': password,
          if (role != null) 'role': role,
          if (villageId != null) 'village_id': villageId,
        },
      );

      // response เป็น Dio Response ต้องใช้ .data
      final responseData = response.data;
      
      debugPrint('🟡 Raw API Response: $responseData');
      debugPrint('🟡 Response Type: ${responseData.runtimeType}');

      // ============================================
      // ตรวจสอบ success จาก response
      // รองรับหลาย format:
      // 1. { "success": true, ... }
      // 2. { "status": "success", ... }
      // 3. { "code": 200, ... }
      // ============================================
      bool isSuccess = false;
      
      if (responseData is Map) {
        isSuccess = responseData['success'] == true ||
                    responseData['status'] == 'success' ||
                    responseData['code'] == 200 ||
                    responseData['code'] == '200';
      }

      if (isSuccess) {
        debugPrint('🟢 Login API Success!');
        
        // ============================================
        // แยก user data จาก response
        // รองรับหลาย format:
        // 1. { success, data: { user_id, ... }, token }
        // 2. { success, user: { ... }, token }
        // 3. { success, data: { user: {...}, token } }
        // ============================================
        Map<String, dynamic>? userData;
        String? token;
        String? refreshToken;
        
        if (responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          // ถ้า data มี user ข้างใน
          if (data['user'] is Map) {
            userData = data['user'] as Map<String, dynamic>;
            token = data['token']?.toString() ?? responseData['token']?.toString();
          } else {
            // data คือ user data โดยตรง
            userData = data;
            token = responseData['token']?.toString() ?? data['token']?.toString();
          }
        } else if (responseData['user'] is Map) {
          userData = responseData['user'] as Map<String, dynamic>;
          token = responseData['token']?.toString();
        }
        
        refreshToken = responseData['refresh_token']?.toString();
        
        debugPrint('🟢 Parsed User Data: $userData');
        debugPrint('🟢 Token: ${token != null ? "มี" : "ไม่มี"}');
        
        return {
          'success': true,
          'user': userData,
          'data': userData,
          'token': token,
          'refresh_token': refreshToken,
          'message': responseData['message']?.toString() ?? 'เข้าสู่ระบบสำเร็จ',
        };
      } else {
        // ============================================
        // Login ไม่สำเร็จ
        // ============================================
        String errorMessage = 'เข้าสู่ระบบไม่สำเร็จ';
        
        if (responseData is Map) {
          errorMessage = responseData['message']?.toString() ??
                        responseData['error']?.toString() ??
                        errorMessage;
        }
        
        debugPrint('🔴 Login API Failed: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      debugPrint('🔴 Login Repository Error: $e');
      
      // แปลง error message
      String errorMessage = e.toString();
      
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Logout
  Future<bool> logout() async {
    try {
      await _apiService.post('/auth/logout.php');
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