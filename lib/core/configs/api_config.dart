class ApiConfig {
  // ============================================
  // Base URL - เปลี่ยนเป็น URL hosting ของคุณ
  // ============================================
  static const String baseUrl = 'https://ets.tswg.site/village-entry-backend/api';
  
  // ============================================
  // Sunmi Endpoints (สำหรับเครื่อง Sunmi)
  // ============================================
  static const String sunmi = '/sunmi';
  static const String sunmiLogin = '$sunmi/login.php';
  static const String sunmiLogout = '$sunmi/logout.php';
  static const String sunmiEntry = '$sunmi/entry.php';
  static const String sunmiExit = '$sunmi/exit.php';
  static const String sunmiSync = '$sunmi/sync.php';
  static const String sunmiQrGenerate = '$sunmi/qr-generate.php';
  
  // ============================================
  // Authentication
  // ============================================
  static const String auth = '/auth';
  static const String login = '$auth/login.php';
  static const String logout = '$auth/logout.php';
  static const String refreshToken = '$auth/refresh.php';
  
  // ============================================
  // Villages
  // ============================================
  static const String villages = '/villages';
  static const String getAllVillages = '$villages/index.php';
  static const String getVillageById = '$villages/view.php';
  static const String createVillage = '$villages/create.php';
  static const String updateVillage = '$villages/update.php';
  static const String deleteVillage = '$villages/delete.php';
  
  // ============================================
  // Users
  // ============================================
  static const String users = '/users';
  static const String getAllUsers = '$users/index.php';
  static const String getUserById = '$users/view.php';
  static const String createUser = '$users/create.php';
  static const String updateUser = '$users/update.php';
  static const String deleteUser = '$users/delete.php';
  static const String toggleUserStatus = '$users/toggle-status.php';
  
  // ============================================
  // Visitors
  // ============================================
  static const String visitors = '/visitors';
  static const String getAllVisitors = '$visitors/index.php';
  static const String getVisitorById = '$visitors/view.php';
  static const String createVisitor = '$visitors/create.php';
  static const String updateVisitor = '$visitors/update.php';
  static const String searchVisitor = '$visitors/search.php';
  static const String uploadVisitorPhoto = '$visitors/upload-photo.php';
  
  // ============================================
  // Entry Logs
  // ============================================
  static const String entryLogs = '/entry-logs';
  static const String getAllEntryLogs = '$entryLogs/index.php';
  static const String getEntryLogById = '$entryLogs/view.php';
  static const String createEntry = '$entryLogs/entry.php';
  static const String createExit = '$entryLogs/exit.php';
  static const String getCurrentVisitors = '$entryLogs/current.php';
  static const String getLogsByDate = '$entryLogs/by-date.php';
  
  // ============================================
  // Reports
  // ============================================
  static const String reports = '/reports';
  static const String getDashboardStats = '$reports/dashboard.php';
  static const String getDailyReport = '$reports/daily.php';
  static const String getMonthlyReport = '$reports/monthly.php';
  static const String getVisitorStats = '$reports/visitor-stats.php';
  static const String exportExcel = '$reports/export-excel.php';
  
  // ============================================
  // Test
  // ============================================
  static const String test = '/test.php';
  
  // ============================================
  // Request Headers
  // ============================================
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // ============================================
  // Timeouts
  // ============================================
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // ============================================
  // Helper Methods
  // ============================================
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  static String replacePath(String path, Map<String, dynamic> params) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
  
  static String addQueryParams(String path, Map<String, dynamic> params) {
    if (params.isEmpty) return path;
    
    final queryString = params.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    if (queryString.isEmpty) return path;
    
    return path.contains('?') 
        ? '$path&$queryString' 
        : '$path?$queryString';
  }
}
