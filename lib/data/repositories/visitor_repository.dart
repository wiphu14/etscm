import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

class VisitorRepository {
  final ApiService _apiService;

  VisitorRepository(this._apiService);

  // ============================================
  // Query Operations
  // ============================================

  Future<List<Map<String, dynamic>>> getAllVisitors({
    int? villageId,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getAllVisitors,
        queryParameters: {
          if (villageId != null) 'village_id': villageId,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get visitors error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchVisitor({
    String? keyword,
    String? phone,
    String? licensePlate,
    String? visitorCode,
    int? villageId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.searchVisitor,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (licensePlate != null && licensePlate.isNotEmpty) 'license_plate': licensePlate,
          if (visitorCode != null && visitorCode.isNotEmpty) 'visitor_code': visitorCode,
          if (villageId != null) 'village_id': villageId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Search visitor error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getVisitorById(int id) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getVisitorById,
        queryParameters: {'id': id},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Get visitor by ID error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVisitorByQRCode(String qrCode) async {
    try {
      final response = await _apiService.get(
        ApiConfig.searchVisitor,
        queryParameters: {'visitor_code': qrCode},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Get visitor by QR code error: $e');
      return null;
    }
  }

  // ============================================
  // CRUD Operations
  // ============================================

  Future<Map<String, dynamic>> addVisitor(Map<String, dynamic> visitorData) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createVisitor,
        data: visitorData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return {
            'success': true,
            'data': response.data['data'],
            'message': response.data['message'] ?? 'เพิ่มผู้มาติดต่อสำเร็จ',
          };
        }
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'เพิ่มผู้มาติดต่อไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('Add visitor error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateVisitor(
    int id,
    Map<String, dynamic> visitorData,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.updateVisitor,
        data: {'id': id, ...visitorData},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'อัปเดตข้อมูลสำเร็จ',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'อัปเดตข้อมูลไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('Update visitor error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteVisitor(int id) async {
    try {
      final response = await _apiService.post(
        ApiConfig.updateVisitor,
        data: {'id': id, 'delete': true},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'ลบข้อมูลสำเร็จ',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'ลบข้อมูลไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('Delete visitor error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Photo Operations
  // ============================================

  Future<Map<String, dynamic>> uploadPhoto({
    required File photoFile,
    required String visitorCode,
    int photoIndex = 1,
    bool useBase64 = false,
  }) async {
    try {
      dynamic response;
      
      if (useBase64) {
        response = await _apiService.uploadImageBase64(
          ApiConfig.uploadVisitorPhoto,
          photoFile,
          additionalData: {
            'visitor_code': visitorCode,
            'photo_index': photoIndex,
          },
        );
      } else {
        response = await _apiService.uploadImage(
          ApiConfig.uploadVisitorPhoto,
          photoFile,
          additionalData: {
            'visitor_code': visitorCode,
            'photo_index': photoIndex,
          },
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return {
            'success': true,
            'photo_url': response.data['data']?['photo_url'] ?? response.data['photo_url'],
            'message': response.data['message'] ?? 'อัปโหลดรูปภาพสำเร็จ',
          };
        }
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'อัปโหลดรูปภาพไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('Upload photo error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadMultiplePhotos({
    required List<File> photoFiles,
    required String visitorCode,
  }) async {
    try {
      List<String> uploadedUrls = [];
      List<String> errors = [];
      
      for (int i = 0; i < photoFiles.length && i < 3; i++) {
        final result = await uploadPhoto(
          photoFile: photoFiles[i],
          visitorCode: visitorCode,
          photoIndex: i + 1,
        );
        
        if (result['success']) {
          uploadedUrls.add(result['photo_url'] ?? '');
        } else {
          errors.add('รูปที่ ${i + 1}: ${result['message']}');
        }
      }
      
      return {
        'success': errors.isEmpty,
        'uploaded_urls': uploadedUrls,
        'uploaded_count': uploadedUrls.length,
        'errors': errors,
        'message': errors.isEmpty 
            ? 'อัปโหลดรูปภาพทั้งหมดสำเร็จ' 
            : 'อัปโหลดบางรูปไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('Upload multiple photos error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Statistics
  // ============================================

  Future<Map<String, dynamic>> getVisitorStats({
    int? villageId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getVisitorStats,
        queryParameters: {
          if (villageId != null) 'village_id': villageId,
          if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('Get visitor stats error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getFrequentVisitors({
    int? villageId,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getAllVisitors,
        queryParameters: {
          if (villageId != null) 'village_id': villageId,
          'order_by': 'visit_count',
          'order': 'desc',
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get frequent visitors error: $e');
      return [];
    }
  }
}
