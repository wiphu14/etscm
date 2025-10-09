import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'visitor_entry_screen.dart';
import 'visitor_exit_screen.dart';
import 'visitor_history_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key}); // แก้ไข error ที่ 1

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  // Mock statistics for today
  final Map<String, dynamic> _todayStats = {
    'total_entries': 15,
    'total_exits': 8,
    'current_visitors': 7,
  };

  // Mock recent entries
  final List<Map<String, dynamic>> _recentEntries = [
    {
      'visitor_name': 'นายสมชาย ใจดี',
      'license_plate': 'กข-1234',
      'house_number': '123/45',
      'entry_time': DateTime.now().subtract(const Duration(minutes: 30)),
      'status': 'entry',
    },
    {
      'visitor_name': 'นางสมหญิง รักงาน',
      'license_plate': 'คค-5678',
      'house_number': '234/56',
      'entry_time': DateTime.now().subtract(const Duration(hours: 1)),
      'status': 'entry',
    },
    {
      'visitor_name': 'นายประยุทธ สุขสม',
      'license_plate': 'งง-9012',
      'house_number': '345/67',
      'entry_time': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'exit',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              AppColors.primary,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(authProvider),

              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32.r),
                      topRight: Radius.circular(32.r),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),

                        // Quick Actions
                        _buildQuickActions(),

                        SizedBox(height: 24.h),

                        // Today Statistics
                        Text('สถิติวันนี้', style: AppTextStyles.h4),
                        SizedBox(height: 16.h),
                        _buildTodayStats(),

                        SizedBox(height: 24.h),

                        // Recent Activities
                        _buildRecentActivitiesHeader(),
                        SizedBox(height: 12.h),
                        _buildRecentActivities(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), // แก้ไข error ที่ 2
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), // แก้ไข error ที่ 3
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 30.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดี, ${authProvider.fullName}',
                      style: AppTextStyles.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.home_work_rounded,
                          size: 14.sp,
                          color: Colors.white.withValues(alpha: 0.9), // แก้ไข error ที่ 4
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            authProvider.villageName ?? '',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9), // แก้ไข error ที่ 5
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showLogoutDialog(),
                icon: Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Date & Time
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15), // แก้ไข error ที่ 6
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  DateFormat('วันEEEที่ d MMM yyyy', 'th').format(DateTime.now()),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.login_rounded,
            label: 'บันทึกเข้า',
            color: AppColors.entry,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VisitorEntryScreen()),
              );
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            icon: Icons.logout_rounded,
            label: 'บันทึกออก',
            color: AppColors.exit,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VisitorExitScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)], // แก้ไข error ที่ 7
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3), // แก้ไข error ที่ 8
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 30.sp, color: Colors.white),
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'เข้า',
            value: '${_todayStats['total_entries']}',
            icon: Icons.arrow_downward_rounded,
            color: AppColors.entry,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            title: 'ออก',
            value: '${_todayStats['total_exits']}',
            icon: Icons.arrow_upward_rounded,
            color: AppColors.exit,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            title: 'อยู่ภายใน',
            value: '${_todayStats['current_visitors']}',
            icon: Icons.people_rounded,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), // แก้ไข error ที่ 9
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('กิจกรรมล่าสุด', style: AppTextStyles.h4),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VisitorHistoryScreen()),
            );
          },
          child: Row(
            children: [
              Text(
                'ดูทั้งหมด',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    if (_recentEntries.isEmpty) {
      return CustomCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.h),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 48.sp,
                  color: AppColors.textHint,
                ),
                SizedBox(height: 12.h),
                Text(
                  'ยังไม่มีกิจกรรม',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _recentEntries.take(5).map((entry) {
        return _buildActivityCard(entry);
      }).toList(),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> entry) {
    final isEntry = entry['status'] == 'entry';
    final statusColor = isEntry ? AppColors.entry : AppColors.exit;
    final timeAgo = _getTimeAgo(entry['entry_time']);

    return CustomCard(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1), // แก้ไข error ที่ 10
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              isEntry ? Icons.login_rounded : Icons.logout_rounded,
              color: statusColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['visitor_name'],
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${entry['license_plate']} • บ้าน ${entry['house_number']}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1), // แก้ไข error ที่ 11
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  isEntry ? 'เข้า' : 'ออก',
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                timeAgo,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return '${difference.inDays} วันที่แล้ว';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( // เปลี่ยนชื่อ parameter เป็น dialogContext
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('ออกจากระบบ', style: AppTextStyles.h4),
        content: Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // ใช้ dialogContext
            child: Text('ยกเลิก', style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // ปิด dialog ก่อน
              await context.read<AuthProvider>().logout(); // แก้ไข error ที่ 12
              if (mounted) { // ตรวจสอบ mounted
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('ออกจากระบบ', style: AppTextStyles.button.copyWith(
              color: AppColors.error,
            )),
          ),
        ],
      ),
    );
  }
}