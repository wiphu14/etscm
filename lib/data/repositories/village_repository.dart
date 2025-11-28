import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

class VillageRepository {
  final ApiService _apiService;

  VillageRepository(this._apiService);

  // ============================================
  // Query Operations
  // ============================================

  Future<List<Map<String, dynamic>>> getAllVillages() async {
    try {
      final response = await _apiService.get(ApiConfig.getAllVillages);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get villages error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getVillageById(int id) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getVillageById,
        queryParameters: {'id': id},
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Get village error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchVillages({
    String? keyword,
    String? province,
    bool? isActive,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getAllVillages,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (province != null && province.isNotEmpty) 'province': province,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Search villages error: $e');
      return [];
    }
  }

  // ============================================
  // CRUD Operations
  // ============================================

  Future<Map<String, dynamic>> createVillage(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createVillage,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return {
            'success': true,
            'data': response.data['data'],
            'message': response.data['message'] ?? 'เพิ่มหมู่บ้านสำเร็จ',
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'เพิ่มหมู่บ้านไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateVillage(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.updateVillage,
        data: {'id': id, ...data},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'แก้ไขข้อมูลสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'แก้ไขข้อมูลไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteVillage(int id) async {
    try {
      final response = await _apiService.post(
        ApiConfig.deleteVillage,
        data: {'id': id},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'ลบหมู่บ้านสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'ลบหมู่บ้านไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Status Operations
  // ============================================

  Future<Map<String, dynamic>> toggleVillageStatus(int id) async {
    try {
      final response = await _apiService.post(
        ApiConfig.updateVillage,
        data: {'id': id, 'toggle_status': true},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'is_active': response.data['data']?['is_active'] ?? true,
          'message': response.data['message'] ?? 'เปลี่ยนสถานะสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'เปลี่ยนสถานะไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Statistics
  // ============================================

  Future<Map<String, dynamic>> getVillageStats(int villageId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getDashboardStats,
        queryParameters: {'village_id': villageId},
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('Get village stats error: $e');
      return {};
    }
  }
}
