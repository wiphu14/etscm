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
      debugPrint('🔵 VillageRepository.getAllVillages() เริ่มทำงาน...');
      debugPrint('🔵 API URL: ${ApiConfig.baseUrl}${ApiConfig.getAllVillages}');
      
      final response = await _apiService.get(ApiConfig.getAllVillages);
      
      debugPrint('🟡 Response Status: ${response.statusCode}');
      debugPrint('🟡 Response Data: ${response.data}');
      debugPrint('🟡 Response Type: ${response.data.runtimeType}');
      
      // ============================================
      // รองรับหลาย format จาก API:
      // 1. { "success": true, "data": [...] }
      // 2. { "status": "success", "data": [...] }
      // 3. [ {...}, {...} ] - Array โดยตรง
      // 4. { "villages": [...] }
      // ============================================
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // กรณี response เป็น List โดยตรง
        if (responseData is List) {
          debugPrint('🟢 Response เป็น List: ${responseData.length} รายการ');
          return responseData.map((e) => e as Map<String, dynamic>).toList();
        }
        
        // กรณี response เป็น Map
        if (responseData is Map) {
          List? dataList;
          
          // ลองหา data จากหลาย key
          if (responseData['data'] is List) {
            dataList = responseData['data'] as List;
          } else if (responseData['villages'] is List) {
            dataList = responseData['villages'] as List;
          } else if (responseData['result'] is List) {
            dataList = responseData['result'] as List;
          }
          
          if (dataList != null) {
            debugPrint('🟢 พบข้อมูลหมู่บ้าน: ${dataList.length} รายการ');
            return dataList.map((e) => e as Map<String, dynamic>).toList();
          }
          
          // ถ้าไม่พบ data แต่ success = true อาจเป็นข้อมูลว่าง
          if (responseData['success'] == true || responseData['status'] == 'success') {
            debugPrint('🟡 API Success แต่ไม่มีข้อมูล');
            return [];
          }
        }
      }
      
      debugPrint('🔴 ไม่สามารถ parse response ได้');
      return [];
    } catch (e, stackTrace) {
      debugPrint('🔴 Get villages error: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getVillageById(int id) async {
    try {
      debugPrint('🔵 getVillageById($id) เริ่มทำงาน...');
      
      final response = await _apiService.get(
        ApiConfig.getVillageById,
        queryParameters: {'id': id},
      );
      
      debugPrint('🟡 Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData is Map) {
          if (responseData['success'] == true && responseData['data'] != null) {
            return responseData['data'] as Map<String, dynamic>;
          }
          // บางกรณี data อยู่ใน root
          if (responseData['village_id'] != null || responseData['id'] != null) {
            return responseData as Map<String, dynamic>;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('🔴 Get village error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchVillages({
    String? keyword,
    String? province,
    bool? isActive,
  }) async {
    try {
      debugPrint('🔵 searchVillages() เริ่มทำงาน...');
      
      final response = await _apiService.get(
        ApiConfig.getAllVillages,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (province != null && province.isNotEmpty) 'province': province,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      );
      
      debugPrint('🟡 Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData is List) {
          return responseData.map((e) => e as Map<String, dynamic>).toList();
        }
        
        if (responseData is Map && responseData['data'] is List) {
          return (responseData['data'] as List).map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🔴 Search villages error: $e');
      return [];
    }
  }

  // ============================================
  // CRUD Operations
  // ============================================

  Future<Map<String, dynamic>> createVillage(Map<String, dynamic> data) async {
    try {
      debugPrint('🔵 createVillage() เริ่มทำงาน...');
      debugPrint('🔵 Data: $data');
      
      final response = await _apiService.post(
        ApiConfig.createVillage,
        data: data,
      );

      debugPrint('🟡 Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'เพิ่มหมู่บ้านสำเร็จ',
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data?['message'] ?? 'เพิ่มหมู่บ้านไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 Create village error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateVillage(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('🔵 updateVillage($id) เริ่มทำงาน...');
      
      final response = await _apiService.post(
        ApiConfig.updateVillage,
        data: {'id': id, ...data},
      );

      debugPrint('🟡 Response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'แก้ไขข้อมูลสำเร็จ',
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data?['message'] ?? 'แก้ไขข้อมูลไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 Update village error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteVillage(int id) async {
    try {
      debugPrint('🔵 deleteVillage($id) เริ่มทำงาน...');
      
      final response = await _apiService.post(
        ApiConfig.deleteVillage,
        data: {'id': id},
      );

      debugPrint('🟡 Response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'ลบหมู่บ้านสำเร็จ',
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data?['message'] ?? 'ลบหมู่บ้านไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 Delete village error: $e');
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

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return {
            'success': true,
            'is_active': responseData['data']?['is_active'] ?? true,
            'message': responseData['message'] ?? 'เปลี่ยนสถานะสำเร็จ',
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data?['message'] ?? 'เปลี่ยนสถานะไม่สำเร็จ',
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
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map) {
          if (responseData['success'] == true && responseData['data'] != null) {
            return responseData['data'] as Map<String, dynamic>;
          }
          return responseData as Map<String, dynamic>;
        }
      }
      return {};
    } catch (e) {
      debugPrint('🔴 Get village stats error: $e');
      return {};
    }
  }
}