import 'package:flutter/foundation.dart';

class VillageProvider with ChangeNotifier {
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get villages => _villages;
  bool get isLoading => _isLoading;

  /// Load villages from database/API
  Future<void> loadVillages() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call - replace with actual database query
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data - replace with actual data from database
      _villages = [
        {
          'id': 1,
          'village_code': 'VL001',
          'village_name': 'หมู่บ้านสวนสยาม 1',
          'address': '123 ถ.พหลโยธิน',
          'province': 'กรุงเทพมหานคร',
          'district': 'จตุจักร',
          'sub_district': 'ลาดยาว',
          'contact_phone': '02-1234567',
          'total_houses': 150,
        },
        {
          'id': 2,
          'village_code': 'VL002',
          'village_name': 'หมู่บ้านมัณฑนา',
          'address': '456 ถ.รามอินทรา',
          'province': 'กรุงเทพมหานคร',
          'district': 'คันนายาว',
          'sub_district': 'คันนายาว',
          'contact_phone': '02-7654321',
          'total_houses': 200,
        },
        {
          'id': 3,
          'village_code': 'VL003',
          'village_name': 'หมู่บ้านเมืองทอง',
          'address': '789 ถ.แจ้งวัฒนะ',
          'province': 'นนทบุรี',
          'district': 'ปากเกร็ด',
          'sub_district': 'บางตลาด',
          'contact_phone': '02-9876543',
          'total_houses': 180,
        },
      ];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Load villages error: $e');
    }
  }

  /// Add new village
  Future<bool> addVillage(Map<String, dynamic> villageData) async {
    try {
      // Generate new ID
      final newId = _villages.isEmpty 
          ? 1 
          : (_villages.map((v) => v['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      
      final newVillage = {
        'id': newId,
        ...villageData,
      };
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      _villages.add(newVillage);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add village error: $e');
      return false;
    }
  }

  /// Update existing village
  Future<bool> updateVillage(int id, Map<String, dynamic> villageData) async {
    try {
      final index = _villages.indexWhere((v) => v['id'] == id);
      if (index == -1) return false;
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      _villages[index] = {
        'id': id,
        ...villageData,
      };
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update village error: $e');
      return false;
    }
  }

  /// Delete village
  Future<bool> deleteVillage(int id) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      _villages.removeWhere((v) => v['id'] == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete village error: $e');
      return false;
    }
  }

  /// Get village by ID
  Map<String, dynamic>? getVillageById(int id) {
    try {
      return _villages.firstWhere((village) => village['id'] == id);
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
      final name = village['village_name']?.toString().toLowerCase() ?? '';
      final code = village['village_code']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      
      return name.contains(searchQuery) || code.contains(searchQuery);
    }).toList();
  }
}