import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/configs/api_config.dart';

/// API Service สำหรับเรียก REST API
class ApiService {
  late Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        // แก้ไข: ใช้ Duration แทน int
        connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
        sendTimeout: Duration(milliseconds: ApiConfig.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // ไม่ throw error สำหรับ 4xx และ 5xx เพื่อให้อ่าน response body ได้
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          
          debugPrint('📤 Request: ${options.method} ${options.uri}');
          if (options.data != null) {
            // Don't log base64 photo data
            var logData = options.data;
            if (logData is Map && logData['photo_base64'] != null) {
              logData = Map.from(logData);
              logData['photo_base64'] = '[BASE64_DATA]';
            }
            debugPrint('📤 Body: $logData');
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('📥 Response [${response.statusCode}]: ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Error [${error.response?.statusCode}]: ${error.message}');
          
          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          }
          
          return handler.next(error);
        },
      ),
    );
  }

  /// Set auth token
  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Get auth token
  String? get authToken => _authToken;

  /// Clear auth token
  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }

  /// Handle unauthorized (401)
  void _handleUnauthorized() {
    clearAuthToken();
    // TODO: Navigate to login screen or refresh token
  }

  /// Refresh token
  Future<bool> refreshToken() async {
    try {
      final response = await _dio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': _authToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newToken = response.data['token'] ?? response.data['data']?['token'];
        if (newToken != null) {
          setAuthToken(newToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('🔴 Refresh token error: $e');
      return false;
    }
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('❌ GET Error: ${e.message}');
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('❌ POST Error: ${e.message}');
      rethrow;
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('❌ PUT Error: ${e.message}');
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('❌ DELETE Error: ${e.message}');
      rethrow;
    }
  }

  /// Upload file
  Future<Response> uploadFile(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response;
    } on DioException catch (e) {
      debugPrint('❌ Upload Error: ${e.message}');
      rethrow;
    }
  }

  /// Test connection
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(ApiConfig.test);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Download file
  Future<Response> downloadFile(
    String url,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('❌ Download Error: ${e.message}');
      rethrow;
    }
  }
}