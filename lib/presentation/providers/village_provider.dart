import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/village_repository.dart';

class VillageProvider with ChangeNotifier {
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get villages => _villages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // API Service & Repository
  late ApiService _apiService;
  late VillageRepository _villageRepository;

  VillageProvider() {
    _apiService = ApiService();
    _villageRepository = VillageRepository(_apiService);
  }

  /// Load villages from API
  Future<void> loadVillages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔵 VillageProvider.loadVillages() เริ่มทำงาน...');
      
      // ============================================
      // โหลดจาก API จริง
      // ============================================
      final villages = await _villageRepository.getAllVillages();
      
      debugPrint('🟢 โหลดหมู่บ้านจาก API: ${villages.length} รายการ');
      
      if (villages.isNotEmpty) {
        _villages = villages;
      } else {
        // ============================================
        // ถ้า API ไม่มีข้อมูล ใช้ Mock Data
        // (สำหรับ Development/Testing)
        // ============================================
        debugPrint('🟡 API ไม่มีข้อมูล - ใช้ Mock Data');
        _villages = _getMockVillages();
      }
      
      _isLoading = false;
      notifyListeners();
      
      debugPrint('🟢 Villages loaded: ${_villages.length}');
      for (var v in _villages) {
        debugPrint('   - ${v['village_name'] ?? v['name']} (ID: ${v['id'] ?? v['village_id']})');
      }
      
    } catch (e, stackTrace) {
      debugPrint('🔴 Load villages error: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      
      // ถ้าเกิด error ใช้ Mock Data
      _villages = _getMockVillages();
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mock data สำหรับ Development
  List<Map<String, dynamic>> _getMockVillages() {
    return [
      {
        'id': 1,
        'village_id': 1,
        'village_code': 'VL001',
        'village_name': 'หมู่บ้านสวนสยาม',
        'name': 'หมู่บ้านสวนสยาม',
        'address': '123 ถ.เสรีไทย',
        'province': 'กรุงเทพมหานคร',
        'district': 'คันนายาว',
        'sub_district': 'คันนายาว',
        'contact_phone': '02-123-4567',
        'total_houses': 150,
        'is_active': true,
        'status': 'active',
      },
      {
        'id': 2,
        'village_id': 2,
        'village_code': 'VL002',
        'village_name': 'หมู่บ้านเมืองทอง',
        'name': 'หมู่บ้านเมืองทอง',
        'address': '456 ถ.แจ้งวัฒนะ',
        'province': 'นนทบุรี',
        'district': 'ปากเกร็ด',
        'sub_district': 'บางตลาด',
        'contact_phone': '02-234-5678',
        'total_houses': 200,
        'is_active': true,
        'status': 'active',
      },
      {
        'id': 3,
        'village_id': 3,
        'village_code': 'VL003',
        'village_name': 'หมู่บ้านพฤกษา',
        'name': 'หมู่บ้านพฤกษา',
        'address': '789 ถ.รังสิต-นครนายก',
        'province': 'ปทุมธานี',
        'district': 'ธัญบุรี',
        'sub_district': 'ประชาธิปัตย์',
        'contact_phone': '02-345-6789',
        'total_houses': 180,
        'is_active': true,
        'status': 'active',
      },
    ];
  }

  /// Add new village
  Future<bool> addVillage(Map<String, dynamic> villageData) async {
    try {
      debugPrint('🔵 addVillage() เริ่มทำงาน...');
      
      final result = await _villageRepository.createVillage(villageData);
      
      if (result['success'] == true) {
        debugPrint('🟢 เพิ่มหมู่บ้านสำเร็จ');
        await loadVillages(); // Reload data
        return true;
      } else {
        debugPrint('🔴 เพิ่มหมู่บ้านไม่สำเร็จ: ${result['message']}');
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('🔴 Add village error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update existing village
  Future<bool> updateVillage(int id, Map<String, dynamic> villageData) async {
    try {
      debugPrint('🔵 updateVillage($id) เริ่มทำงาน...');
      
      final result = await _villageRepository.updateVillage(id, villageData);
      
      if (result['success'] == true) {
        debugPrint('🟢 แก้ไขหมู่บ้านสำเร็จ');
        await loadVillages(); // Reload data
        return true;
      } else {
        debugPrint('🔴 แก้ไขหมู่บ้านไม่สำเร็จ: ${result['message']}');
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('🔴 Update village error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete village
  Future<bool> deleteVillage(int id) async {
    try {
      debugPrint('🔵 deleteVillage($id) เริ่มทำงาน...');
      
      final result = await _villageRepository.deleteVillage(id);
      
      if (result['success'] == true) {
        debugPrint('🟢 ลบหมู่บ้านสำเร็จ');
        await loadVillages(); // Reload data
        return true;
      } else {
        debugPrint('🔴 ลบหมู่บ้านไม่สำเร็จ: ${result['message']}');
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('🔴 Delete village error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get village by ID
  Map<String, dynamic>? getVillageById(int id) {
    try {
      return _villages.firstWhere(
        (village) => (village['id'] ?? village['village_id']) == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get village by code
  Map<String, dynamic>? getVillageByCode(String code) {
    try {
      return _villages.firstWhere(
        (village) => village['village_code'] == code,
      );
    } catch (e) {
      return null;
    }
  }

  /// Search villages by name
  List<Map<String, dynamic>> searchVillages(String query) {
    if (query.isEmpty) return _villages;
    
    return _villages.where((village) {
      final name = (village['village_name'] ?? village['name'] ?? '').toString().toLowerCase();
      final code = (village['village_code'] ?? '').toString().toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return name.contains(searchQuery) || code.contains(searchQuery);
    }).toList();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}