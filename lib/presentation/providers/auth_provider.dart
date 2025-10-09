import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _username;
  String? _fullName;
  String? _role;
  int? _villageId;
  String? _villageName;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get role => _role;
  int? get villageId => _villageId;
  String? get villageName => _villageName;
  
  bool get isAdmin => _role == 'admin';
  bool get isUser => _role == 'user';

  // Login
  Future<bool> login({
    required String username,
    required String password,
    required String role,
    int? villageId,
  }) async {
    try {
      // TODO: Uncomment to use real API
      /*
      final apiService = ApiService();
      final authRepository = AuthRepository(apiService);
      
      final result = await authRepository.login(
        username: username,
        password: password,
        role: role,
        villageId: villageId,
      );
      
      if (result['success']) {
        final user = result['user'];
        _isAuthenticated = true;
        _userId = user['id'].toString();
        _username = user['username'];
        _fullName = user['full_name'];
        _role = user['role'];
        _villageId = user['village_id'];
        _villageName = user['village_name'];
        
        await _saveAuthData();
        notifyListeners();
        return true;
      }
      return false;
      */
      
      // Mock authentication (for testing without API)
      await Future.delayed(const Duration(seconds: 2));
      
      if ((username == 'admin' && password == 'admin123' && role == 'admin') ||
          (username == 'user001' && password == 'admin123' && role == 'user')) {
        
        _isAuthenticated = true;
        _userId = role == 'admin' ? '1' : '2';
        _username = username;
        _fullName = role == 'admin' ? 'ผู้ดูแลระบบ' : 'สมชาย ใจดี';
        _role = role;
        _villageId = villageId;
        _villageName = villageId != null ? 'หมู่บ้านสวนสยาม 1' : null;
        
        await _saveAuthData();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
    _username = null;
    _fullName = null;
    _role = null;
    _villageId = null;
    _villageName = null;
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  // Save authentication data
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
  }

  // Load authentication data
  Future<void> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _userId = prefs.getString('userId');
    _username = prefs.getString('username');
    _fullName = prefs.getString('fullName');
    _role = prefs.getString('role');
    _villageId = prefs.getInt('villageId');
    _villageName = prefs.getString('villageName');
    
    notifyListeners();
  }
}