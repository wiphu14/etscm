import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../../core/configs/api_config.dart';

/// Repository สำหรับจัดการ Entry Logs
class EntryLogRepository {
  final ApiService _apiService;

  EntryLogRepository(this._apiService);

  /// สร้างรายการเข้าใหม่ (สำหรับ Sunmi)
  Future<Map<String, dynamic>> createEntrySunmi({
    int? villageId,
    Map<String, dynamic>? visitorData,
    Map<String, dynamic>? entryData,
    File? photoFile,
    String? photoBase64,
    String? deviceUuid,
  }) async {
    try {
      debugPrint('🔵 createEntrySunmi เริ่มทำงาน...');

      final requestData = <String, dynamic>{
        'village_id': villageId ?? visitorData?['village_id'] ?? entryData?['village_id'] ?? 1,
        'full_name': visitorData?['full_name'] ?? '',
        'id_card': visitorData?['id_card'] ?? '',
        'phone': visitorData?['phone'] ?? '',
        'vehicle_type': visitorData?['vehicle_type'] ?? 'รถยนต์',
        'license_plate': visitorData?['license_plate'] ?? '',
        'house_number': entryData?['house_number'] ?? '',
        'resident_name': entryData?['resident_name'] ?? '',
        'purpose': entryData?['purpose'] ?? '',
        'purpose_detail': entryData?['purpose_detail'] ?? '',
        'entry_by': entryData?['entry_by'],
        'entry_notes': entryData?['entry_notes'] ?? '',
        'device_uuid': deviceUuid ?? 'sunmi-app-${DateTime.now().millisecondsSinceEpoch}',
      };

      // แปลงรูปภาพเป็น base64
      if (photoFile != null && await photoFile.exists()) {
        try {
          final bytes = await photoFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          requestData['photo_base64'] = base64Image;
          debugPrint('🟢 Photo converted to base64: ${bytes.length} bytes');
        } catch (e) {
          debugPrint('🟡 Warning: Cannot convert photo to base64: $e');
        }
      } else if (photoBase64 != null && photoBase64.isNotEmpty) {
        requestData['photo_base64'] = photoBase64;
        debugPrint('🟢 Using provided base64 photo');
      }

      debugPrint('🔵 Request Data Keys: ${requestData.keys.toList()}');

      final response = await _apiService.post(
        ApiConfig.createEntrySunmi,
        data: requestData,
      );

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Data: ${response.data}');

      // Handle error responses (4xx)
      if (response.statusCode != null && response.statusCode! >= 400) {
        String errorMessage = 'เกิดข้อผิดพลาด (${response.statusCode})';
        if (response.data != null) {
          if (response.data is Map) {
            errorMessage = (response.data['message'] as String?) ?? errorMessage;
            debugPrint('🔴 Server Error Message: $errorMessage');
          } else {
            errorMessage = response.data.toString();
          }
        }
        return {'success': false, 'message': errorMessage};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map) {
          if (responseData['success'] == true) {
            debugPrint('🟢 บันทึกสำเร็จ');
            return {
              'success': true,
              'message': responseData['message'] ?? 'บันทึกสำเร็จ',
              'data': responseData['data'],
            };
          } else {
            final msg = (responseData['message'] as String?) ?? 'บันทึกไม่สำเร็จ';
            debugPrint('🔴 API returned success=false: $msg');
            return {'success': false, 'message': msg};
          }
        }
      }
      return {'success': false, 'message': 'Invalid response from server'};
    } on DioException catch (e) {
      // แสดง response body เมื่อเกิด error
      debugPrint('🔴 DioException: ${e.message}');
      debugPrint('🔴 Response Status: ${e.response?.statusCode}');
      debugPrint('🔴 Response Data: ${e.response?.data}');
      
      String errorMessage = 'เกิดข้อผิดพลาด';
      if (e.response?.data != null) {
        final responseData = e.response?.data;
        if (responseData is Map) {
          errorMessage = (responseData['message'] as String?) ?? errorMessage;
        } else if (responseData != null) {
          errorMessage = responseData.toString();
        }
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e, stackTrace) {
      debugPrint('🔴 createEntrySunmi Error: $e');
      debugPrint('🔴 Stack: $stackTrace');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ดึงสถิติ Dashboard
  Future<Map<String, dynamic>> getDashboardStats({
    int? villageId,
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (villageId != null) queryParams['village_id'] = villageId;
      if (date != null) queryParams['date'] = date.toIso8601String().split('T')[0];

      final response = await _apiService.get(
        ApiConfig.getDashboardStats,
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
      debugPrint('🔴 getDashboardStats Error: $e');
      return {};
    }
  }

  /// ดึงรายการ Entry Logs
  Future<List<Map<String, dynamic>>> getEntryLogs({
    int? villageId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (villageId != null) queryParams['village_id'] = villageId;
      if (status != null) queryParams['status'] = status;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String().split('T')[0];

      final response = await _apiService.get(
        ApiConfig.getEntryLogs,
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
      debugPrint('🔴 getEntryLogs Error: $e');
      return [];
    }
  }

  /// ดึงรายการ Logs ตามวันที่
  Future<List<Map<String, dynamic>>> getLogsByDate({
    required DateTime date,
    int? villageId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'date': date.toIso8601String().split('T')[0],
      };
      if (villageId != null) queryParams['village_id'] = villageId;

      final response = await _apiService.get(
        ApiConfig.getEntryLogsByDate,
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
      debugPrint('🔴 getLogsByDate Error: $e');
      return [];
    }
  }

  /// ดึงรายการผู้อยู่ภายใน (Current Visitors)
  Future<List<Map<String, dynamic>>> getCurrentVisitors({
    int? villageId,
  }) async {
    try {
      debugPrint('🔵 getCurrentVisitors เริ่มทำงาน...');
      
      final queryParams = <String, dynamic>{};
      if (villageId != null) queryParams['village_id'] = villageId;

      // ลองเรียก API ใหม่ก่อน
      try {
        final response = await _apiService.get(
          '/sunmi/current-inside.php',
          queryParameters: queryParams,
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map && data['success'] == true && data['data'] is List) {
            debugPrint('🟢 getCurrentVisitors (new API): ${(data['data'] as List).length} รายการ');
            return (data['data'] as List).map((e) => e as Map<String, dynamic>).toList();
          }
        }
      } catch (e) {
        debugPrint('🟡 New API failed, trying old API: $e');
      }

      // Fallback: เรียก API เดิม
      queryParams['status'] = 'inside';
      final response = await _apiService.get(
        ApiConfig.getEntryLogs,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          debugPrint('🟢 getCurrentVisitors (fallback): ${data.length} รายการ');
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
        if (data is Map && data['data'] is List) {
          debugPrint('🟢 getCurrentVisitors (fallback): ${(data['data'] as List).length} รายการ');
          return (data['data'] as List).map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🔴 getCurrentVisitors Error: $e');
      return [];
    }
  }

  /// ดึงรายการผู้อยู่ภายใน (alias)
  Future<List<Map<String, dynamic>>> getCurrentInside({int? villageId}) async {
    return getCurrentVisitors(villageId: villageId);
  }

  /// บันทึกการออก
  Future<Map<String, dynamic>> recordExit({
    required int logId,
    required int exitBy,
    String? exitNotes,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.recordExit,
        data: {
          'log_id': logId,
          'exit_by': exitBy,
          'exit_notes': exitNotes ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'บันทึกออกสำเร็จ',
            'data': data['data'],
          };
        }
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'บันทึกออกไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 recordExit Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// บันทึกการออก (Sunmi) - alias
  Future<Map<String, dynamic>> createExitSunmi({
    int? logId,
    int? exitBy,
    String? exitNotes,
    String? notes,
    String? deviceUuid,
    String? qrCode,
  }) async {
    try {
      final data = <String, dynamic>{
        'exit_by': exitBy ?? 0,
        'exit_notes': exitNotes ?? notes ?? '',
        'device_uuid': deviceUuid ?? '',
      };
      
      if (logId != null) {
        data['log_id'] = logId;
      }
      if (qrCode != null) {
        data['qr_code'] = qrCode;
      }

      final response = await _apiService.post(
        ApiConfig.exitSunmi,
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'บันทึกออกสำเร็จ',
            'data': responseData['data'],
          };
        }
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'บันทึกออกไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 createExitSunmi Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ดึง Entry Log ตาม ID
  Future<Map<String, dynamic>?> getEntryLogById(int logId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.getEntryLogById,
        queryParameters: {'id': logId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          if (data['success'] == true && data['data'] != null) {
            return data['data'] as Map<String, dynamic>;
          }
          if (data['log_id'] != null) {
            return data as Map<String, dynamic>;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('🔴 getEntryLogById Error: $e');
      return null;
    }
  }

  /// ยกเลิก Entry
  Future<Map<String, dynamic>> cancelEntry({
    required int logId,
    required int cancelBy,
    String? reason,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.cancelEntry,
        data: {
          'log_id': logId,
          'cancel_by': cancelBy,
          'reason': reason ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return {'success': true, 'message': data['message'] ?? 'ยกเลิกสำเร็จ'};
        }
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'ยกเลิกไม่สำเร็จ',
      };
    } catch (e) {
      debugPrint('🔴 cancelEntry Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// สร้างรายการเข้าพร้อมรูปภาพ
  Future<Map<String, dynamic>> createEntryWithPhoto({
    required int villageId,
    required Map<String, dynamic> visitorData,
    required Map<String, dynamic> entryData,
    required File photoFile,
    String? deviceUuid,
  }) async {
    return createEntrySunmi(
      villageId: villageId,
      visitorData: visitorData,
      entryData: entryData,
      photoFile: photoFile,
      deviceUuid: deviceUuid,
    );
  }
}