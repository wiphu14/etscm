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
      debugPrint('🔵 createEntrySunmi เริ่มทำงาน...');
      
      // รวม visitor และ entry data เข้าด้วยกัน
      final requestData = {
        // Visitor Data
        'village_id': visitorData['village_id'] ?? entryData['village_id'],
        'full_name': visitorData['full_name'] ?? '',
        'id_card': visitorData['id_card'] ?? '',
        'phone': visitorData['phone'] ?? '',
        'vehicle_type': visitorData['vehicle_type'] ?? 'รถยนต์',
        'license_plate': visitorData['license_plate'] ?? '',
        
        // Entry Data
        'house_number': entryData['house_number'] ?? '',
        'resident_name': entryData['resident_name'] ?? '',
        'purpose': entryData['purpose'] ?? 'ไม่ระบุ',
        'purpose_detail': entryData['purpose_detail'] ?? '',
        'entry_by': entryData['entry_by'],
        'entry_notes': entryData['entry_notes'] ?? '',
        
        // Device info - ใช้ค่าเริ่มต้นถ้าไม่มี
        'device_uuid': 'sunmi-app-${DateTime.now().millisecondsSinceEpoch}',
      };

      debugPrint('🔵 Request Data: $requestData');
      
      final response = await _apiService.post(
        ApiConfig.sunmiEntry,
        data: requestData,
      );

      debugPrint('🟡 Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return {
            'success': true,
            'data': response.data['data'],
            'message': response.data['message'] ?? 'บันทึกผู้เข้าสำเร็จ',
            'qr_code': response.data['data']?['qr_code'] ?? response.data['qr_code'],
            'log_id': response.data['data']?['log_id'] ?? response.data['log_id'],
          };
        }
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'บันทึกไม่สำเร็จ',
      };
    } catch (e, stackTrace) {
      debugPrint('🔴 createEntrySunmi Error: $e');
      debugPrint('🔴 Stack: $stackTrace');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createExitSunmi({
    required String qrCode,
    String? notes,
  }) async {
    try {
      debugPrint('🔵 createExitSunmi เริ่มทำงาน...');
      debugPrint('🔵 QR Code: $qrCode');
      
      final response = await _apiService.post(
        ApiConfig.sunmiExit,
        data: {
          'qr_code': qrCode,
          'exit_time': DateTime.now().toIso8601String(),
          'exit_notes': notes ?? '',
          'device_uuid': 'sunmi-app-${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      debugPrint('🟡 Response: ${response.data}');

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
      debugPrint('🔴 createExitSunmi Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // Entry - Web/Admin (ใช้ endpoint เดียวกับ Sunmi)
  // ============================================

  Future<Map<String, dynamic>> createEntry({
    required Map<String, dynamic> visitorData,
    required Map<String, dynamic> entryData,
  }) async {
    return createEntrySunmi(
      visitorData: visitorData,
      entryData: entryData,
    );
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
          if (notes != null) 'exit_notes': notes,
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
      debugPrint('🔵 getCurrentVisitors เริ่มทำงาน...');
      debugPrint('🔵 Village ID: $villageId');
      
      final response = await _apiService.get(
        ApiConfig.getCurrentVisitors,
        queryParameters: {
          if (villageId != null) 'village_id': villageId,
        },
      );
      
      debugPrint('🟡 Response: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          final List data = response.data['data'] ?? [];
          debugPrint('🟢 พบผู้อยู่ภายใน ${data.length} คน');
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
        
        if (response.data is List) {
          return (response.data as List).map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🔴 getCurrentVisitors Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLogsByDate({
    required DateTime date,
    int? villageId,
  }) async {
    try {
      debugPrint('🔵 getLogsByDate เริ่มทำงาน...');
      debugPrint('🔵 Date: ${date.toIso8601String().split('T')[0]}');
      
      final response = await _apiService.get(
        ApiConfig.getLogsByDate,
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
          if (villageId != null) 'village_id': villageId,
        },
      );
      
      debugPrint('🟡 Response: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          final List data = response.data['data'] ?? [];
          debugPrint('🟢 พบประวัติ ${data.length} รายการ');
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
        
        if (response.data is List) {
          return (response.data as List).map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🔴 getLogsByDate Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEntryHistory({
    required DateTime date,
    int? villageId,
    String? status,
  }) async {
    try {
      debugPrint('🔵 getEntryHistory เริ่มทำงาน...');
      
      final response = await _apiService.get(
        '/entry/history.php',
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
          if (villageId != null) 'village_id': villageId,
          if (status != null && status != 'all') 'status': status,
        },
      );
      
      debugPrint('🟡 Response: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          final List data = response.data['data'] ?? [];
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🔴 getEntryHistory Error: $e');
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
      debugPrint('🔴 searchLogs Error: $e');
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
      debugPrint('🔴 getLogById Error: $e');
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
      debugPrint('🔵 getDashboardStats เริ่มทำงาน...');
      debugPrint('🔵 Village ID: $villageId');
      
      final response = await _apiService.get(
        ApiConfig.getDashboardStats,
        queryParameters: {
          if (villageId != null) 'village_id': villageId,
          if (date != null) 'date': date.toIso8601String().split('T')[0],
        },
      );
      
      debugPrint('🟡 Response: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data['success'] == true && response.data['data'] != null) {
          final data = response.data['data'];
          return {
            'today_entries': data['today_entries'] ?? data['total_entries'] ?? 0,
            'today_exits': data['today_exits'] ?? data['total_exits'] ?? 0,
            'current_inside': data['current_inside'] ?? data['current_visitors'] ?? 0,
            'total_visitors': data['total_visitors'] ?? 0,
            'total_users': data['total_users'] ?? 0,
            'total_villages': data['total_villages'] ?? 0,
          };
        }
        
        if (response.data['today_entries'] != null || response.data['current_inside'] != null) {
          return {
            'today_entries': response.data['today_entries'] ?? 0,
            'today_exits': response.data['today_exits'] ?? 0,
            'current_inside': response.data['current_inside'] ?? 0,
            'total_visitors': response.data['total_visitors'] ?? 0,
            'total_users': response.data['total_users'] ?? 0,
            'total_villages': response.data['total_villages'] ?? 0,
          };
        }
      }
      
      return _defaultStats();
    } catch (e) {
      debugPrint('🔴 getDashboardStats Error: $e');
      return _defaultStats();
    }
  }

  Map<String, dynamic> _defaultStats() => {
    'today_entries': 0,
    'today_exits': 0,
    'current_inside': 0,
    'total_visitors': 0,
    'total_users': 0,
    'total_villages': 0,
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
      debugPrint('🔴 getDailyReport Error: $e');
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
      debugPrint('🔴 getMonthlyReport Error: $e');
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
