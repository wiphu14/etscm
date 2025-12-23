import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _token;
  String? _role;
  int? _userId;
  int? _villageId;
  String? _username;
  String? _fullName;
  String? _villageName;
  String? _errorMessage;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get role => _role;
  int? get userId => _userId;
  int? get villageId => _villageId;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get villageName => _villageName;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _role == 'admin';

  // API Service & Repository
  final ApiService _apiService = ApiService();
  late final AuthRepository _authRepository;

  AuthProvider() {
    _authRepository = AuthRepository(_apiService);
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _role = prefs.getString('role');
      _userId = prefs.getInt('user_id');
      _villageId = prefs.getInt('village_id');
      _username = prefs.getString('username');
      _fullName = prefs.getString('full_name');
      _villageName = prefs.getString('village_name');
      
      if (_token != null && _token!.isNotEmpty) {
        _isLoggedIn = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load session error: $e');
    }
  }

  Future<bool> login({
    required String username,
    required String password,
    String? role,
    int? villageId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔵 ========================================');
      debugPrint('🔵 เริ่มต้น Login...');
      debugPrint('🔵 Username: $username');
      debugPrint('🔵 Role ที่เลือก: ${role ?? "auto-detect"}');
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
        debugPrint('🟢 Login สำเร็จ!');
        
        // ============================================
        // ดึงข้อมูล user จาก response
        // รองรับหลาย format จาก API:
        // 1. { success, data: { user_id, username, role, ... }, token }
        // 2. { success, user: { ... }, token }
        // 3. { success, data: { user: { ... }, token } }
        // ============================================
        final userData = result['user'] ?? result['data'] ?? {};
        
        debugPrint('🟢 User Data: $userData');
        
        if (userData != null && userData is Map) {
          // รองรับทั้ง 'id' และ 'user_id'
          _userId = _parseIntSafe(userData['user_id'] ?? userData['id']);
          _username = userData['username']?.toString();
          _fullName = userData['full_name']?.toString() ?? userData['fullName']?.toString();
          _villageId = _parseIntSafe(userData['village_id'] ?? userData['villageId'] ?? villageId);
          _villageName = userData['village_name']?.toString() ?? userData['villageName']?.toString();
          
          // ============================================
          // สำคัญ: ใช้ role จาก API response ไม่ใช่จาก parameter
          // เพราะ API จะตรวจสอบ role จากฐานข้อมูล
          // ============================================
          _role = userData['role']?.toString() ?? role ?? 'user';
        }
        
        _token = result['token']?.toString();
        
        // ถ้าไม่มี role จาก API ให้ใช้ role ที่ส่งไป หรือ default เป็น 'user'
        _role ??= role ?? 'user';
        
        _isLoggedIn = true;
        
        // บันทึก session
        await _saveSession();

        debugPrint('🟢 ========================================');
        debugPrint('🟢 Login สำเร็จ!');
        debugPrint('🟢 User ID: $_userId');
        debugPrint('🟢 Username: $_username');
        debugPrint('🟢 Full Name: $_fullName');
        debugPrint('🟢 Role จาก API: $_role');
        debugPrint('🟢 Village ID: $_villageId');
        debugPrint('🟢 Village Name: $_villageName');
        debugPrint('🟢 ========================================');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message']?.toString() ?? 'เข้าสู่ระบบไม่สำเร็จ';
        debugPrint('🔴 Login ไม่สำเร็จ: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 ========================================');
      debugPrint('🔴 Login Error: $e');
      debugPrint('🔴 Stack Trace: $stackTrace');
      debugPrint('🔴 ========================================');
      _errorMessage = _parseErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper: แปลง dynamic เป็น int อย่างปลอดภัย
  int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // Helper: แปลง error message
  String _parseErrorMessage(dynamic error) {
    if (error == null) return 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
    
    String message = error.toString();
    
    // ลบ prefix "Exception:" ถ้ามี
    if (message.startsWith('Exception:')) {
      message = message.replaceFirst('Exception:', '').trim();
    }
    
    // แปลง error messages ภาษาอังกฤษเป็นภาษาไทย
    if (message.contains('Invalid credentials') || 
        message.contains('invalid_credentials')) {
      return 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
    }
    if (message.contains('User not found') || 
        message.contains('user_not_found')) {
      return 'ไม่พบผู้ใช้งานนี้ในระบบ';
    }
    if (message.contains('Account locked') || 
        message.contains('account_locked')) {
      return 'บัญชีถูกระงับการใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง';
    }
    if (message.contains('Account inactive') || 
        message.contains('account_inactive')) {
      return 'บัญชีนี้ถูกปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ';
    }
    if (message.contains('connection') || 
        message.contains('network') ||
        message.contains('timeout')) {
      return 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
    }
    if (message.contains('Role mismatch') || 
        message.contains('role_mismatch')) {
      return 'ประเภทผู้ใช้ไม่ถูกต้อง กรุณาเลือกประเภทที่ถูกต้อง';
    }
    
    return message;
  }

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString('token', _token!);
      if (_role != null) await prefs.setString('role', _role!);
      if (_userId != null) await prefs.setInt('user_id', _userId!);
      if (_villageId != null) await prefs.setInt('village_id', _villageId!);
      if (_username != null) await prefs.setString('username', _username!);
      if (_fullName != null) await prefs.setString('full_name', _fullName!);
      if (_villageName != null) await prefs.setString('village_name', _villageName!);
      
      debugPrint('🟢 บันทึก Session สำเร็จ');
    } catch (e) {
      debugPrint('🔴 Save session error: $e');
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🔵 Logging out...');
      
      // Clear local state
      _isLoggedIn = false;
      _token = null;
      _role = null;
      _userId = null;
      _villageId = null;
      _username = null;
      _fullName = null;
      _villageName = null;
      _errorMessage = null;

      // Clear saved session
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      debugPrint('🟢 Logout สำเร็จ!');
      notifyListeners();
    } catch (e) {
      debugPrint('🔴 Logout error: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // เพิ่มฟังก์ชันสำหรับอัปเดตข้อมูล user
  // ============================================
  void updateUserInfo({
    String? fullName,
    String? villageName,
    int? villageId,
  }) {
    if (fullName != null) _fullName = fullName;
    if (villageName != null) _villageName = villageName;
    if (villageId != null) _villageId = villageId;
    _saveSession();
    notifyListeners();
  }
}