import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/configs/api_config.dart';

class ApiService {
  late Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add token to header
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        debugPrint('Request: ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('Response: ${response.statusCode} ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('Error: ${error.response?.statusCode} ${error.message}');
        
        // Handle 401 Unauthorized
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        
        return handler.next(error);
      },
    ));

    _loadToken();
  }

  // Load token from SharedPreferences
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token
  Future<void> _clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Refresh token
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['token'];
        await _saveToken(newToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Retry request
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle errors
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
        errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์';
        break;
      default:
        errorMessage = 'เกิดข้อผิดพลาดที่ไม่คาดคิด';
    }

    return Exception(errorMessage);
  }

  // Get error message from response
  String _getErrorMessage(Response? response) {
    if (response == null) return 'เกิดข้อผิดพลาด';

    try {
      if (response.data is Map) {
        return response.data['message'] ?? 
               response.data['error'] ?? 
               'เกิดข้อผิดพลาด';
      }
      return 'เกิดข้อผิดพลาด';
    } catch (e) {
      return 'เกิดข้อผิดพลาด';
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String role,
    int? villageId,
  }) async {
    final response = await post(
      ApiConfig.login,
      data: {
        'username': username,
        'password': password,
        'role': role,
        if (villageId != null) 'village_id': villageId,
      },
    );

    if (response.statusCode == 200) {
      final token = response.data['token'];
      final refreshToken = response.data['refresh_token'];
      
      await _saveToken(token);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', refreshToken);
      
      return response.data;
    }

    throw Exception('Login failed');
  }

  // Upload image with multipart
  Future<Response> uploadImage(
    String path,
    File imageFile, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String fileName = imageFile.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload image as Base64
  Future<Response> uploadImageBase64(
    String path,
    File imageFile, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Convert to base64
      final base64Image = base64Encode(bytes);
      
      // Get file extension
      final extension = imageFile.path.split('.').last;

      final response = await _dio.post(
        path,
        data: {
          'image': base64Image,
          'extension': extension,
          if (additionalData != null) ...additionalData,
        },
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await post(ApiConfig.logout);
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _clearToken();
    }
  }
}