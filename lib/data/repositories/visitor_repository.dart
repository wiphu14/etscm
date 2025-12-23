import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

/// Repository สำหรับจัดการ Visitors
class VisitorRepository {
  final ApiService _apiService;

  VisitorRepository(this._apiService);

  /// ดึงรายการ Visitors ทั้งหมด
  Future<List<Map<String, dynamic>>> getAllVisitors({
    int? villageId,
    String? keyword,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (villageId != null) queryParams['village_id'] = villageId;
      if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;

      final response = await _apiService.get(
        ApiConfig.getAllVisitors,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List).map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🔴 getAllVisitors Error: $e');
      return [];
    }
  }

  /// ดึง Visitor ตาม ID
  Future<Map<String, dynamic>?> getVisitorById(int visitorId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getVisitorById,
        queryParameters: {'id': visitorId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          if (data['success'] == true && data['data'] != null) {
            return data['data'] as Map<String, dynamic>;
          }
          if (data['visitor_id'] != null) {
            return data as Map<String, dynamic>;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('🔴 getVisitorById Error: $e');
      return null;
    }
  }

  /// ค้นหา Visitor
  Future<List<Map<String, dynamic>>> searchVisitor({
    String? keyword,
    String? idCard,
    String? licensePlate,
    int? villageId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
      if (idCard != null && idCard.isNotEmpty) queryParams['id_card'] = idCard;
      if (licensePlate != null && licensePlate.isNotEmpty) queryParams['license_plate'] = licensePlate;
      if (villageId != null) queryParams['village_id'] = villageId;

      final response = await _apiService.get(
        ApiConfig.searchVisitor,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List).map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🔴 searchVisitor Error: $e');
      return [];
    }
  }

  /// สร้าง Visitor ใหม่
  Future<Map<String, dynamic>> createVisitor({
    required int villageId,
    required String fullName,
    required String idCard,
    String? phone,
    String? vehicleType,
    String? licensePlate,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createVisitor,
        data: {
          'village_id': villageId,
          'full_name': fullName,
          'id_card': idCard,
          'phone': phone ?? '',
          'vehicle_type': vehicleType ?? 'รถยนต์',
          'license_plate': licensePlate ?? '',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'สร้างผู้เข้าสำเร็จ',
            'data': data['data'],
          };
        }
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'สร้างผู้เข้าไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 createVisitor Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// อัปเดต Visitor
  Future<Map<String, dynamic>> updateVisitor({
    required int visitorId,
    String? fullName,
    String? phone,
    String? vehicleType,
    String? licensePlate,
  }) async {
    try {
      final data = <String, dynamic>{'visitor_id': visitorId};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (vehicleType != null) data['vehicle_type'] = vehicleType;
      if (licensePlate != null) data['license_plate'] = licensePlate;

      final response = await _apiService.post(
        ApiConfig.updateVisitor,
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'อัปเดตผู้เข้าสำเร็จ',
          };
        }
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'อัปเดตผู้เข้าไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 updateVisitor Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// อัปโหลดรูปภาพ Visitor
  Future<Map<String, dynamic>> uploadVisitorPhoto({
    required int visitorId,
    required File photoFile,
  }) async {
    try {
      final fileName = photoFile.path.split('/').last;
      final formData = FormData.fromMap({
        'visitor_id': visitorId,
        'photo': await MultipartFile.fromFile(photoFile.path, filename: fileName),
      });

      final response = await _apiService.post(
        ApiConfig.uploadVisitorPhoto,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'อัปโหลดรูปภาพสำเร็จ',
            'photo_path': data['photo_path'] ?? data['data']?['photo_path'],
          };
        }
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'อัปโหลดรูปภาพไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 uploadVisitorPhoto Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// อัปโหลดรูปภาพ Visitor (base64)
  Future<Map<String, dynamic>> uploadVisitorPhotoBase64({
    required int visitorId,
    required String base64Photo,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.uploadVisitorPhoto,
        data: {
          'visitor_id': visitorId,
          'photo_base64': base64Photo,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'อัปโหลดรูปภาพสำเร็จ',
            'photo_path': data['photo_path'] ?? data['data']?['photo_path'],
          };
        }
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'อัปโหลดรูปภาพไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 uploadVisitorPhotoBase64 Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ดึงสถิติ Visitor
  Future<Map<String, dynamic>> getVisitorStats({int? villageId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (villageId != null) queryParams['village_id'] = villageId;

      final response = await _apiService.get(
        ApiConfig.getVisitorStats,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          if (data['success'] == true && data['data'] != null) {
            return data['data'] as Map<String, dynamic>;
          }
          return data as Map<String, dynamic>;
        }
      }
      return {};
    } catch (e) {
      debugPrint('🔴 getVisitorStats Error: $e');
      return {};
    }
  }

  /// ดึงประวัติการเข้าของ Visitor
  Future<List<Map<String, dynamic>>> getVisitorHistory({
    required int visitorId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getAllVisitors,
        queryParameters: {
          'visitor_id': visitorId,
          'history': true,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List).map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🔴 getVisitorHistory Error: $e');
      return [];
    }
  }

  /// อัปโหลดรูปภาพ (alias for uploadVisitorPhoto)
  Future<Map<String, dynamic>> uploadPhoto({
    int? visitorId,
    String? visitorCode,
    File? photoFile,
    String? photoBase64,
    int? photoIndex,
  }) async {
    try {
      // ถ้าไม่มี visitorId ให้ใช้ visitorCode แทน
      final id = visitorId ?? 0;
      
      if (photoFile != null) {
        return uploadVisitorPhoto(visitorId: id, photoFile: photoFile);
      } else if (photoBase64 != null) {
        return uploadVisitorPhotoBase64(visitorId: id, base64Photo: photoBase64);
      }
      return {'success': false, 'message': 'No photo provided'};
    } catch (e) {
      debugPrint('🔴 uploadPhoto Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}