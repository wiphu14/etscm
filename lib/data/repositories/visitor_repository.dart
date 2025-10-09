import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

class VisitorRepository {
  final ApiService _apiService;

  VisitorRepository(this._apiService);

  /// Upload visitor photo
  Future<Map<String, dynamic>> uploadPhoto({
    required File photoFile,
    required String visitorCode,
    bool useBase64 = false,
  }) async {
    try {
      dynamic response;
      
      if (useBase64) {
        // Upload as Base64
        response = await _apiService.uploadImageBase64(
          '${ApiConfig.visitors}/upload-photo',
          photoFile,
          additionalData: {
            'visitor_code': visitorCode,
          },
        );
      } else {
        // Upload as Multipart
        response = await _apiService.uploadImage(
          '${ApiConfig.visitors}/upload-photo',
          photoFile,
          additionalData: {
            'visitor_code': visitorCode,
          },
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'photo_url': response.data['photo_url'],
          'message': 'อัปโหลดรูปภาพสำเร็จ',
        };
      }

      return {
        'success': false,
        'message': 'อัปโหลดรูปภาพไม่สำเร็จ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get all visitors
  Future<List<Map<String, dynamic>>> getAllVisitors({
    int? villageId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getAllVisitors,
        queryParameters: {
          if (villageId != null) 'village_id': villageId,
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get visitors error: $e');
      return [];
    }
  }

  /// Search visitor
  Future<List<Map<String, dynamic>>> searchVisitor({
    String? keyword,
    String? phone,
    String? licensePlate,
    int? villageId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.searchVisitor,
        queryParameters: {
          if (keyword != null) 'keyword': keyword,
          if (phone != null) 'phone': phone,
          if (licensePlate != null) 'license_plate': licensePlate,
          if (villageId != null) 'village_id': villageId,
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Search visitor error: $e');
      return [];
    }
  }

  /// Get visitor by ID
  Future<Map<String, dynamic>?> getVisitorById(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.visitors}/$id');

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Get visitor by ID error: $e');
      return null;
    }
  }

  /// Add new visitor
  Future<Map<String, dynamic>> addVisitor(Map<String, dynamic> visitorData) async {
    try {
      final response = await _apiService.post(
        ApiConfig.visitors,
        data: visitorData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': 'เพิ่มผู้มาติดต่อสำเร็จ',
        };
      }

      return {
        'success': false,
        'message': 'เพิ่มผู้มาติดต่อไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('Add visitor error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Update visitor
  Future<Map<String, dynamic>> updateVisitor(
    int id,
    Map<String, dynamic> visitorData,
  ) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.visitors}/$id',
        data: visitorData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': 'อัปเดตข้อมูลสำเร็จ',
        };
      }

      return {
        'success': false,
        'message': 'อัปเดตข้อมูลไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('Update visitor error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Delete visitor
  Future<Map<String, dynamic>> deleteVisitor(int id) async {
    try {
      final response = await _apiService.delete('${ApiConfig.visitors}/$id');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'ลบข้อมูลสำเร็จ',
        };
      }

      return {
        'success': false,
        'message': 'ลบข้อมูลไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('Delete visitor error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}