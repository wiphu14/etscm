import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _username;
  String? _fullName;
  String? _role;
  int? _villageId;
  String? _villageName;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get role => _role;
  int? get villageId => _villageId;
  String? get villageName => _villageName;
  String? get token => _token;
  
  bool get isAdmin => _role == 'admin';
  bool get isUser => _role == 'user';

  // API Service & Repository
  late ApiService _apiService;
  late AuthRepository _authRepository;

  AuthProvider() {
    _apiService = ApiService();
    _authRepository = AuthRepository(_apiService);
  }

  // ============================================
  // Login - เชื่อมต่อ API จริง
  // ============================================
  Future<bool> login({
    required String username,
    required String password,
    required String role,
    int? villageId,
  }) async {
    try {
      debugPrint('🔵 ========================================');
      debugPrint('🔵 เริ่มต้น Login...');
      debugPrint('🔵 Username: $username');
      debugPrint('🔵 Role: $role');
      debugPrint('🔵 Village ID: $villageId');
      debugPrint('🔵 ========================================');

      final result = await _authRepository.login(
        username: username,
        password: password,
        role: role,
        villageId: villageId,
      );

      debugPrint('🟡 Login Response: $result');

      if (result['success'] == true) {
        final user = result['user'];
        
        debugPrint('🟢 Login สำเร็จ!');
        debugPrint('🟢 User Data: $user');

        _isAuthenticated = true;
        _userId = user['id']?.toString() ?? '';
        _username = user['username'] ?? username;
        _fullName = user['full_name'] ?? user['fullName'] ?? '';
        _role = user['role'] ?? role;
        _villageId = user['village_id'] ?? villageId;
        _villageName = user['village_name'] ?? '';
        _token = result['token'];

        await _saveAuthData();
        notifyListeners();
        
        debugPrint('🟢 บันทึกข้อมูล Auth สำเร็จ');
        return true;
      }

      debugPrint('🔴 Login ไม่สำเร็จ: ${result['message']}');
      return false;
      
    } catch (e, stackTrace) {
      debugPrint('🔴 ========================================');
      debugPrint('🔴 Login Error: $e');
      debugPrint('🔴 Stack Trace: $stackTrace');
      debugPrint('🔴 ========================================');
      return false;
    }
  }

  // ============================================
  // Login สำหรับ Sunmi Device
  // ============================================
  Future<bool> loginSunmi({
    required String username,
    required String password,
    required String deviceUuid,
  }) async {
    try {
      debugPrint('🔵 ========================================');
      debugPrint('🔵 เริ่มต้น Login Sunmi...');
      debugPrint('🔵 Username: $username');
      debugPrint('🔵 Device UUID: $deviceUuid');
      debugPrint('🔵 ========================================');

      final result = await _authRepository.loginSunmi(
        username: username,
        password: password,
        deviceUuid: deviceUuid,
      );

      debugPrint('🟡 Login Sunmi Response: $result');

      if (result['success'] == true) {
        final user = result['user'];
        final village = result['village'];
        
        debugPrint('🟢 Login Sunmi สำเร็จ!');
        debugPrint('🟢 User: $user');
        debugPrint('🟢 Village: $village');

        _isAuthenticated = true;
        _userId = user?['id']?.toString() ?? '';
        _username = user?['username'] ?? username;
        _fullName = user?['full_name'] ?? '';
        _role = 'user';
        _villageId = village?['id'];
        _villageName = village?['name'] ?? village?['village_name'] ?? '';
        _token = result['token'];

        await _saveAuthData();
        notifyListeners();
        
        debugPrint('🟢 บันทึกข้อมูล Auth Sunmi สำเร็จ');
        return true;
      }

      debugPrint('🔴 Login Sunmi ไม่สำเร็จ: ${result['message']}');
      return false;
      
    } catch (e, stackTrace) {
      debugPrint('🔴 ========================================');
      debugPrint('🔴 Login Sunmi Error: $e');
      debugPrint('🔴 Stack Trace: $stackTrace');
      debugPrint('🔴 ========================================');
      return false;
    }
  }

  // ============================================
  // Logout
  // ============================================
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    
    _isAuthenticated = false;
    _userId = null;
    _username = null;
    _fullName = null;
    _role = null;
    _villageId = null;
    _villageName = null;
    _token = null;
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  // ============================================
  // Save authentication data
  // ============================================
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('userId', _userId ?? '');
    await prefs.setString('username', _username ?? '');
    await prefs.setString('fullName', _fullName ?? '');
    await prefs.setString('role', _role ?? '');
    if (_villageId != null) {
      await prefs.setInt('villageId', _villageId!);
    }
    if (_villageName != null) {
      await prefs.setString('villageName', _villageName!);
    }
    if (_token != null) {
      await prefs.setString('auth_token', _token!);
    }
  }

  // ============================================
  // Load authentication data
  // ============================================
  Future<void> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _userId = prefs.getString('userId');
    _username = prefs.getString('username');
    _fullName = prefs.getString('fullName');
    _role = prefs.getString('role');
    _villageId = prefs.getInt('villageId');
    _villageName = prefs.getString('villageName');
    _token = prefs.getString('auth_token');
    
    notifyListeners();
  }

  // ============================================
  // Test Connection
  // ============================================
  Future<Map<String, dynamic>> testConnection() async {
    try {
      debugPrint('🔵 ทดสอบการเชื่อมต่อ...');
      final result = await _authRepository.testConnection();
      debugPrint('🟢 ผลการทดสอบ: $result');
      return result;
    } catch (e) {
      debugPrint('🔴 Test Connection Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}