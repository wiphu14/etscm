import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

class VillageRepository {
  final ApiService _apiService;

  VillageRepository(this._apiService);

  /// Get all villages
  Future<List<Map<String, dynamic>>> getAllVillages() async {
    try {
      final response = await _apiService.get(ApiConfig.getAllVillages);
      
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Get villages error: $e');
      return [];
    }
  }

  /// Get village by ID
  Future<Map<String, dynamic>?> getVillageById(int id) async {
    try {
      final path = ApiConfig.replacePath(
        ApiConfig.getVillageById,
        {'id': id},
      );
      final response = await _apiService.get(path);
      
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Get village error: $e');
      return null;
    }
  }

  /// Create village
  Future<Map<String, dynamic>> createVillage(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createVillage,
        data: data,
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': 'เพิ่มหมู่บ้านสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': 'เพิ่มหมู่บ้านไม่สำเร็จ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Update village
  Future<Map<String, dynamic>> updateVillage(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final path = ApiConfig.replacePath(
        ApiConfig.updateVillage,
        {'id': id},
      );
      final response = await _apiService.put(path, data: data);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': 'แก้ไขข้อมูลสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': 'แก้ไขข้อมูลไม่สำเร็จ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Delete village
  Future<Map<String, dynamic>> deleteVillage(int id) async {
    try {
      final path = ApiConfig.replacePath(
        ApiConfig.deleteVillage,
        {'id': id},
      );
      final response = await _apiService.delete(path);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'ลบหมู่บ้านสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': 'ลบหมู่บ้านไม่สำเร็จ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}