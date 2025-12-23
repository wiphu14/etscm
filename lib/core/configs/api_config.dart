/// API Configuration
/// กำหนด Base URL และ Endpoints ทั้งหมดสำหรับระบบ Village Entry
/// 
/// อ้างอิงโครงสร้าง Backend จริง
/// 
class ApiConfig {
  // ============================================
  // Base URL
  // ============================================
  static const String baseUrl = 'https://ets.tswg.site/village-entry-backend/api';
  static const String uploadBaseUrl = 'https://ets.tswg.site/village-entry-backend';
  
  // ============================================
  // Auth Endpoints - /api/auth/
  // ============================================
  static const String login = '/auth/login.php';
  static const String logout = '/auth/logout.php';
  static const String refreshToken = '/auth/refresh.php';
  
  // ============================================
  // Sunmi Device Endpoints - /api/sunmi/
  // ============================================
  static const String createEntrySunmi = '/sunmi/entry.php';
  static const String exitSunmi = '/sunmi/exit.php';
  static const String sunmiLogin = '/sunmi/login.php';
  static const String sunmiSync = '/sunmi/sync.php';
  static const String sunmiConfig = '/sunmi/config.php';
  static const String sunmiQrGenerate = '/sunmi/qr-generate.php';
  static const String sunmiTest = '/sunmi/test.php';
  static const String test = '/sunmi/test.php';
  
  // ============================================
  // Entry Endpoints - /api/entry/
  // ============================================
  static const String createEntry = '/entry/create.php';
  static const String currentEntry = '/entry/current.php';
  static const String entryHistory = '/entry/history.php';
  static const String searchEntry = '/entry/search.php';
  static const String entryStats = '/entry/stats.php';
  
  // ============================================
  // Exit Endpoints - /api/exit/
  // ============================================
  static const String recordExit = '/exit/create.php';
  static const String cancelEntry = '/entry/cancel.php';
  
  // ============================================
  // Entry Logs Endpoints - /api/entry-logs/
  // ============================================
  static const String getEntryLogs = '/entry-logs/current.php';
  static const String getEntryLogById = '/entry-logs/detail.php';
  static const String getEntryLogsByDate = '/entry-logs/by-date.php';
  
  // ============================================
  // Dashboard Endpoints - /api/dashboard/
  // ============================================
  static const String getDashboardDetail = '/dashboard/get-detail.php';
  
  // ============================================
  // Stats Endpoints - /api/stats/
  // ============================================
  static const String getDashboardStats = '/stats/dashboard.php';
  
  // ============================================
  // Village Endpoints - /api/villages/
  // ============================================
  static const String getAllVillages = '/villages/index.php';
  static const String getVillageList = '/villages/list.php';
  static const String getVillageById = '/villages/detail.php';
  static const String createVillage = '/villages/create.php';
  static const String updateVillage = '/villages/update.php';
  static const String deleteVillage = '/villages/delete.php';
  static const String getVillageStats = '/villages/stats.php';
  
  // ============================================
  // User Endpoints - /api/users/
  // ============================================
  static const String getUsers = '/users/index.php';
  static const String getUserList = '/users/list.php';
  static const String getUserById = '/users/detail.php';
  static const String createUser = '/users/create.php';
  static const String updateUser = '/users/update.php';
  static const String deleteUser = '/users/delete.php';
  static const String updateUserStatus = '/users/update-status.php';
  static const String changePassword = '/users/change-password.php';
  
  // ============================================
  // Visitor Endpoints - /api/visitors/
  // ============================================
  static const String getAllVisitors = '/visitors/search.php';
  static const String getVisitorById = '/visitors/search.php';
  static const String searchVisitor = '/visitors/search.php';
  static const String createVisitor = '/visitors/create.php';
  static const String updateVisitor = '/visitors/update.php';
  static const String uploadVisitorPhoto = '/photos/upload.php';
  static const String getVisitorStats = '/stats/dashboard.php';
  
  // ============================================
  // Logs Endpoints - /api/logs/
  // ============================================
  static const String getCurrentLogs = '/logs/current.php';
  
  // ============================================
  // Photos Endpoints - /api/photos/
  // ============================================
  static const String getPhotoDetail = '/photos/detail.php';
  static const String getPhotoList = '/photos/list.php';
  
  // ============================================
  // Reports Endpoints - /api/reports/
  // ============================================
  static const String getReportsDashboard = '/reports/dashboard.php';
  static const String getReportsStats = '/reports/stats.php';
  static const String exportDaily = '/reports/export-daily.php';
  static const String exportExcel = '/reports/export-excel.php';
  static const String exportSummary = '/reports/export-summary.php';
  
  // ============================================
  // Settings Endpoints - /api/settings/
  // ============================================
  static const String getSettings = '/settings/get-settings.php';
  static const String saveEntry = '/settings/save-entry.php';
  static const String saveProfile = '/settings/save-profile.php';
  static const String saveVillage = '/settings/save-village.php';
  static const String saveSystem = '/settings/save-system.php';
  static const String saveSecurity = '/settings/save-security.php';
  static const String saveNotification = '/settings/save-notification.php';
  static const String clearCache = '/settings/clear-cache.php';
  static const String clearOldLogs = '/settings/clear-old-logs.php';
  static const String exportAll = '/settings/export-all.php';
  
  // ============================================
  // LINE Notify Endpoints - /api/line/
  // ============================================
  static const String lineNotifyEntry = '/line/notify-entry.php';
  static const String lineNotifyExit = '/line/notify-exit.php';
  static const String lineSaveSettings = '/line/save-settings.php';
  static const String lineSaveToken = '/line/save-token.php';
  static const String lineTestNotify = '/line/test-notify.php';
  
  // ============================================
  // Timeout Settings (milliseconds)
  // ============================================
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 60000;
  
  // ============================================
  // Helper Methods
  // ============================================
  static String getFullUrl(String endpoint) {
    return baseUrl + endpoint;
  }
  
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$uploadBaseUrl/$path';
  }
}