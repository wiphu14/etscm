import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/configs/api_config.dart';

class ApiService {
  late Dio _dio;
  String? _token;
  String? _deviceUuid;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        if (_deviceUuid != null) {
          options.headers['X-Device-UUID'] = _deviceUuid;
        }
        debugPrint('📤 Request: ${options.method} ${options.uri}');
        debugPrint('📤 Body: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('📥 Response [${response.statusCode}]: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('❌ Error [${error.response?.statusCode}]: ${error.message}');
        
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));

    _loadToken();
  }

  // ============================================
  // Token Management
  // ============================================

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _deviceUuid = prefs.getString('device_uuid');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _saveDeviceUuid(String uuid) async {
    _deviceUuid = uuid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_uuid', uuid);
  }

  Future<void> _clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newToken = response.data['data']['token'];
        await _saveToken(newToken);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Refresh token error: $e');
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $_token',
      },
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // ============================================
  // HTTP Methods
  // ============================================

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // Error Handling
  // ============================================

  Exception _handleError(DioException error) {
    String errorMessage = 'เกิดข้อผิดพลาด';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _getErrorMessage(error.response);
        break;
      case DioExceptionType.cancel:
        errorMessage = 'คำขอถูกยกเลิก';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
        break;
      default:
        errorMessage = 'เกิดข้อผิดพลาดที่ไม่คาดคิด';
    }

    return Exception(errorMessage);
  }

  String _getErrorMessage(Response? response) {
    if (response == null) return 'เกิดข้อผิดพลาด';

    try {
      if (response.data is Map) {
        return response.data['message'] ?? 
               response.data['error'] ?? 
               'เกิดข้อผิดพลาด (${response.statusCode})';
      }
      return 'เกิดข้อผิดพลาด (${response.statusCode})';
    } catch (e) {
      return 'เกิดข้อผิดพลาด';
    }
  }

  // ============================================
  // Authentication - Sunmi Device
  // ============================================

  Future<Map<String, dynamic>> loginSunmi({
    required String username,
    required String password,
    required String deviceUuid,
  }) async {
    try {
      final response = await post(
        ApiConfig.sunmiLogin,
        data: {
          'username': username,
          'password': password,
          'device_uuid': deviceUuid,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _saveToken(data['token']);
        await _saveDeviceUuid(deviceUuid);
        
        if (data['refresh_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('refresh_token', data['refresh_token']);
        }
        
        return response.data;
      }

      throw Exception(response.data['message'] ?? 'Login failed');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // Authentication - Web/Admin
  // ============================================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String role,
    int? villageId,
  }) async {
    try {
      final response = await post(
        ApiConfig.login,
        data: {
          'username': username,
          'password': password,
          'role': role,
          if (villageId != null) 'village_id': villageId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _saveToken(data['token']);
        
        if (data['refresh_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('refresh_token', data['refresh_token']);
        }
        
        return response.data;
      }

      throw Exception(response.data['message'] ?? 'Login failed');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await post(ApiConfig.logout);
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _clearToken();
    }
  }

  // ============================================
  // Image Upload
  // ============================================

  Future<Response> uploadImage(
    String path,
    File imageFile, {
    Map<String, dynamic>? additionalData,
    String fieldName = 'image',
  }) async {
    try {
      String fileName = imageFile.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(imageFile.path, filename: fileName),
        if (additionalData != null) ...additionalData,
      });

      return await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            if (_token != null) 'Authorization': 'Bearer $_token',
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadImageBase64(
    String path,
    File imageFile, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final extension = imageFile.path.split('.').last;

      return await _dio.post(
        path,
        data: {
          'image': base64Image,
          'extension': extension,
          if (additionalData != null) ...additionalData,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // Test Connection
  // ============================================

  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await get(ApiConfig.test);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
