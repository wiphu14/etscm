import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/custom_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notifyEntry = true;
  bool _notifyExit = true;
  bool _notifyOvernight = true;
  bool _notifyDailyReport = true;
  bool _notifySystem = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyEntry = prefs.getBool('notify_entry') ?? true;
      _notifyExit = prefs.getBool('notify_exit') ?? true;
      _notifyOvernight = prefs.getBool('notify_overnight') ?? true;
      _notifyDailyReport = prefs.getBool('notify_daily_report') ?? true;
      _notifySystem = prefs.getBool('notify_system') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตั้งค่าการแจ้งเตือน', style: AppTextStyles.appBarTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            CustomCard(
              padding: EdgeInsets.all(16.w),
              color: AppColors.surfaceLight,
              child: Row(
                children: [
                  Icon(Icons.notifications_active_rounded, 
                    color: AppColors.primary, 
                    size: 32.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'การแจ้งเตือน',
                          style: AppTextStyles.h4,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'เลือกประเภทการแจ้งเตือนที่ต้องการรับ',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Notification Types
            Text('ประเภทการแจ้งเตือน', style: AppTextStyles.h4),
            SizedBox(height: 16.h),

            _buildNotificationTile(
              icon: Icons.login_rounded,
              title: 'ผู้เข้าใหม่',
              subtitle: 'แจ้งเตือนเมื่อมีผู้เข้าหมู่บ้าน',
              value: _notifyEntry,
              color: AppColors.entry,
              onChanged: (value) {
                setState(() => _notifyEntry = value);
                _saveSetting('notify_entry', value);
              },
            ),

            _buildNotificationTile(
              icon: Icons.logout_rounded,
              title: 'ผู้ออก',
              subtitle: 'แจ้งเตือนเมื่อมีผู้ออกจากหมู่บ้าน',
              value: _notifyExit,
              color: AppColors.exit,
              onChanged: (value) {
                setState(() => _notifyExit = value);
                _saveSetting('notify_exit', value);
              },
            ),

            _buildNotificationTile(
              icon: Icons.nights_stay_rounded,
              title: 'ผู้ค้างคืน',
              subtitle: 'แจ้งเตือนเมื่อมีผู้อยู่เกิน 12 ชั่วโมง',
              value: _notifyOvernight,
              color: AppColors.warning,
              onChanged: (value) {
                setState(() => _notifyOvernight = value);
                _saveSetting('notify_overnight', value);
              },
            ),

            _buildNotificationTile(
              icon: Icons.assessment_rounded,
              title: 'รายงานประจำวัน',
              subtitle: 'แจ้งเตือนสรุปยอดรายวัน (18:00 น.)',
              value: _notifyDailyReport,
              color: AppColors.info,
              onChanged: (value) {
                setState(() => _notifyDailyReport = value);
                _saveSetting('notify_daily_report', value);
              },
            ),

            _buildNotificationTile(
              icon: Icons.settings_rounded,
              title: 'ระบบ',
              subtitle: 'แจ้งเตือนจากระบบและการอัปเดต',
              value: _notifySystem,
              color: AppColors.textSecondary,
              onChanged: (value) {
                setState(() => _notifySystem = value);
                _saveSetting('notify_system', value);
              },
            ),

            SizedBox(height: 24.h),

            // Test Notification Button
            CustomCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ทดสอบการแจ้งเตือน',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'กดปุ่มด้านล่างเพื่อทดสอบว่าการแจ้งเตือนทำงานถูกต้อง',
                    style: AppTextStyles.caption,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _testNotification(),
                          icon: Icon(Icons.notification_add_rounded, size: 20.sp),
                          label: Text('ทดสอบ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // FCM Token (for debugging)
            FutureBuilder<String?>(
              future: NotificationService().getFCMToken(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                
                return CustomCard(
                  padding: EdgeInsets.all(16.w),
                  color: AppColors.surfaceLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FCM Token (สำหรับ Dev)',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        snapshot.data ?? '',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10.sp,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return CustomCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 26.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    await NotificationService().showNotification(
      title: '🔔 ทดสอบการแจ้งเตือน',
      body: 'ระบบแจ้งเตือนทำงานปกติ ✅',
      payload: 'test',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งการแจ้งเตือนทดสอบแล้ว'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}