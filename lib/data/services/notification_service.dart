import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize Firebase messaging
    await _initializeFirebaseMessaging();

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    // Show local notification
    showNotification(
      title: message.notification?.title ?? 'แจ้งเตือน',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle notification taps
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to specific screen based on payload
  }

  /// Handle notification tap from Firebase
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification opened: ${message.notification?.title}');
    // TODO: Navigate to specific screen
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'village_entry_channel',
      'Village Entry',
      channelDescription: 'Notifications for village entry system',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show notification with action buttons
  Future<void> showNotificationWithActions({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'village_entry_channel',
      'Village Entry',
      channelDescription: 'Notifications for village entry system',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view',
          'ดูรายละเอียด',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'dismiss',
          'ปิด',
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show scheduled notification
  Future<void> showScheduledNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'village_entry_channel',
      'Village Entry',
      channelDescription: 'Notifications for village entry system',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Note: Requires timezone package for scheduling
    // await _localNotifications.zonedSchedule(
    //   id,
    //   title,
    //   body,
    //   tz.TZDateTime.from(scheduledTime, tz.local),
    //   details,
    //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    //   uiLocalNotificationDateInterpretation:
    //       UILocalNotificationDateInterpretation.absoluteTime,
    //   payload: payload,
    // );
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Predefined notification types
  
  /// แจ้งเตือนผู้เข้าใหม่
  Future<void> notifyNewEntry({
    required String visitorName,
    required String houseNumber,
  }) async {
    await showNotificationWithActions(
      title: '🔔 ผู้เข้าใหม่',
      body: '$visitorName เข้าบ้านเลขที่ $houseNumber',
      payload: 'entry',
    );
  }

  /// แจ้งเตือนผู้ออก
  Future<void> notifyExit({
    required String visitorName,
    required String houseNumber,
  }) async {
    await showNotification(
      title: '👋 ผู้ออก',
      body: '$visitorName ออกจากบ้านเลขที่ $houseNumber',
      payload: 'exit',
    );
  }

  /// แจ้งเตือนผู้ค้างคืน
  Future<void> notifyOvernight({
    required String visitorName,
    required String houseNumber,
    required int hours,
  }) async {
    await showNotificationWithActions(
      title: '⏰ แจ้งเตือนผู้ค้างคืน',
      body: '$visitorName อยู่ที่บ้านเลขที่ $houseNumber นาน $hours ชั่วโมงแล้ว',
      payload: 'overnight',
    );
  }

  /// แจ้งเตือนรายงานประจำวัน
  Future<void> notifyDailyReport({
    required int totalEntries,
    required int totalExits,
    required int currentVisitors,
  }) async {
    await showNotification(
      title: '📊 รายงานประจำวัน',
      body: 'เข้า: $totalEntries | ออก: $totalExits | อยู่ภายใน: $currentVisitors คน',
      payload: 'daily_report',
    );
  }

  /// แจ้งเตือนระบบ
  Future<void> notifySystem({
    required String title,
    required String message,
  }) async {
    await showNotification(
      title: '⚙️ $title',
      body: message,
      payload: 'system',
    );
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}