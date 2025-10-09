import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

class EntryLogRepository {
  final ApiService _apiService;

  EntryLogRepository(this._apiService);

  /// Create entry log (บันทึกเข้า)
  Future<Map<String, dynamic>> createEntry({
    required Map<String, dynamic> visitorData,
    required Map<String, dynamic> entryData,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createEntry,
        data: {
          'visitor': visitorData,
          'entry': entryData,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': 'บันทึกผู้เข้าสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': 'บันทึกไม่สำเร็จ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Create exit log (บันทึกออก)
  Future<Map<String, dynamic>> createExit({
    required int logId,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createExit,
        data: {
          'log_id': logId,
          'exit_time': DateTime.now().toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': 'บันทึกผู้ออกสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': 'บันทึกไม่สำเร็จ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get current visitors (ผู้ที่อยู่ภายใน)
  Future<List<Map<String, dynamic>>> getCurrentVisitors({
    int? villageId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getCurrentVisitors,
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
      print('Get current visitors error: $e');
      return [];
    }
  }

  /// Get logs by date
  Future<List<Map<String, dynamic>>> getLogsByDate({
    required DateTime date,
    int? villageId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getLogsByDate,
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
          if (villageId != null) 'village_id': villageId,
        },
      );
      
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Get logs by date error: $e');
      return [];
    }
  }

  /// Search entry logs
  Future<List<Map<String, dynamic>>> searchLogs({
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
    int? villageId,
    String? status, // 'inside', 'completed'
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getAllEntryLogs,
        queryParameters: {
          if (keyword != null) 'keyword': keyword,
          if (startDate != null) 
            'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 
            'end_date': endDate.toIso8601String().split('T')[0],
          if (villageId != null) 'village_id': villageId,
          if (status != null) 'status': status,
        },
      );
      
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Search logs error: $e');
      return [];
    }
  }

  /// Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats({
    int? villageId,
    DateTime? date,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getDashboardStats,
        queryParameters: {
          if (villageId != null) 'village_id': villageId,
          if (date != null) 'date': date.toIso8601String().split('T')[0],
        },
      );
      
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return {
        'total_entries': 0,
        'total_exits': 0,
        'current_visitors': 0,
      };
    } catch (e) {
      print('Get dashboard stats error: $e');
      return {
        'total_entries': 0,
        'total_exits': 0,
        'current_visitors': 0,
      };
    }
  }
}