import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

class EntryLogRepository {
  final ApiService _apiService;

  EntryLogRepository(this._apiService);

  // ============================================
  // Entry - Sunmi Device
  // ============================================

  Future<Map<String, dynamic>> createEntrySunmi({
    required Map<String, dynamic> visitorData,
    required Map<String, dynamic> entryData,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.sunmiEntry,
        data: {
          'visitor': visitorData,
          'entry': entryData,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return {
            'success': true,
            'data': response.data['data'],
            'message': response.data['message'] ?? 'บันทึกผู้เข้าสำเร็จ',
            'qr_code': response.data['data']?['qr_code'],
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'บันทึกไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createExitSunmi({
    required String qrCode,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.sunmiExit,
        data: {
          'qr_code': qrCode,
          'exit_time': DateTime.now().toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'บันทึกผู้ออกสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'บันทึกไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Entry - Web/Admin
  // ============================================

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return {
            'success': true,
            'data': response.data['data'],
            'message': response.data['message'] ?? 'บันทึกผู้เข้าสำเร็จ',
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'บันทึกไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

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

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'บันทึกผู้ออกสำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'บันทึกไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Query Operations
  // ============================================

  Future<List<Map<String, dynamic>>> getCurrentVisitors({int? villageId}) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getCurrentVisitors,
        queryParameters: {
          if (villageId != null) 'village_id': villageId,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get current visitors error: $e');
      return [];
    }
  }

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
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get logs by date error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchLogs({
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
    int? villageId,
    String? status,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getAllEntryLogs,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
          if (villageId != null) 'village_id': villageId,
          if (status != null) 'status': status,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Search logs error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLogById(int id) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getEntryLogById,
        queryParameters: {'id': id},
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Get log by id error: $e');
      return null;
    }
  }

  // ============================================
  // Dashboard & Reports
  // ============================================

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
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? _defaultStats();
      }
      return _defaultStats();
    } catch (e) {
      debugPrint('Get dashboard stats error: $e');
      return _defaultStats();
    }
  }

  Map<String, dynamic> _defaultStats() => {
    'total_entries': 0,
    'total_exits': 0,
    'current_visitors': 0,
  };

  Future<Map<String, dynamic>> getDailyReport({
    required DateTime date,
    int? villageId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getDailyReport,
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
          if (villageId != null) 'village_id': villageId,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('Get daily report error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getMonthlyReport({
    required int year,
    required int month,
    int? villageId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getMonthlyReport,
        queryParameters: {
          'year': year,
          'month': month,
          if (villageId != null) 'village_id': villageId,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('Get monthly report error: $e');
      return {};
    }
  }

  // ============================================
  // Sync - Sunmi Offline
  // ============================================

  Future<Map<String, dynamic>> syncOfflineData({
    required List<Map<String, dynamic>> entries,
    required List<Map<String, dynamic>> exits,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.sunmiSync,
        data: {
          'entries': entries,
          'exits': exits,
          'sync_time': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'synced_entries': response.data['data']?['synced_entries'] ?? 0,
          'synced_exits': response.data['data']?['synced_exits'] ?? 0,
          'message': response.data['message'] ?? 'Sync สำเร็จ',
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'Sync ไม่สำเร็จ',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
