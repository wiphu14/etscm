class ApiConfig {
  // Base URL - แก้ไขเป็น URL hosting ของคุณ
  static const String baseUrl = 'https://your-domain.com/api';
  
  // API Endpoints
  static const String auth = '/auth';
  static const String villages = '/villages';
  static const String users = '/users';
  static const String visitors = '/visitors';
  static const String entryLogs = '/entry-logs';
  static const String reports = '/reports';
  
  // Authentication
  static const String login = '$auth/login';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  
  // Villages
  static const String getAllVillages = villages;
  static const String getVillageById = '$villages/{id}';
  static const String createVillage = villages;
  static const String updateVillage = '$villages/{id}';
  static const String deleteVillage = '$villages/{id}';
  
  // Users
  static const String getAllUsers = users;
  static const String getUserById = '$users/{id}';
  static const String createUser = users;
  static const String updateUser = '$users/{id}';
  static const String deleteUser = '$users/{id}';
  static const String toggleUserStatus = '$users/{id}/toggle-status';
  
  // Visitors
  static const String getAllVisitors = visitors;
  static const String getVisitorById = '$visitors/{id}';
  static const String createVisitor = visitors;
  static const String updateVisitor = '$visitors/{id}';
  static const String searchVisitor = '$visitors/search';
  
  // Entry Logs
  static const String getAllEntryLogs = entryLogs;
  static const String getEntryLogById = '$entryLogs/{id}';
  static const String createEntry = '$entryLogs/entry';
  static const String createExit = '$entryLogs/exit';
  static const String getCurrentVisitors = '$entryLogs/current';
  static const String getLogsByDate = '$entryLogs/by-date';
  
  // Reports
  static const String getDashboardStats = '$reports/dashboard';
  static const String getDailyReport = '$reports/daily';
  static const String getMonthlyReport = '$reports/monthly';
  static const String getVisitorStats = '$reports/visitor-stats';
  
  // Request Headers
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Helper method to replace path parameters
  static String replacePath(String path, Map<String, dynamic> params) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}