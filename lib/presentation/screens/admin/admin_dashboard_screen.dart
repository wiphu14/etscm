import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'village_management_screen.dart';
import 'user_management_screen.dart';
import 'reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Mock statistics
  final Map<String, dynamic> _stats = {
    'total_villages': 3,
    'total_users': 12,
    'total_visitors_today': 45,
    'total_entries_today': 28,
    'total_exits_today': 17,
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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

                        // Statistics Cards
                        Text(
                          'สถิติวันนี้',
                          style: AppTextStyles.h4,
                        ),
                        SizedBox(height: 16.h),
                        _buildStatisticsGrid(),

                        SizedBox(height: 24.h),

                        // Menu Section
                        Text(
                          'เมนูจัดการ',
                          style: AppTextStyles.h4,
                        ),
                        SizedBox(height: 16.h),
                        _buildMenuGrid(),
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
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.admin.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'ผู้ดูแลระบบ',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    );
  }

  Widget _buildStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'หมู่บ้านทั้งหมด',
                value: '${_stats['total_villages']}',
                icon: Icons.home_work_rounded,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                title: 'ผู้ใช้งาน',
                value: '${_stats['total_users']}',
                icon: Icons.people_rounded,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'ผู้มาติดต่อวันนี้',
                value: '${_stats['total_visitors_today']}',
                icon: Icons.person_rounded,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'เข้า',
                value: '${_stats['total_entries_today']}',
                icon: Icons.login_rounded,
                color: AppColors.entry,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                title: 'ออก',
                value: '${_stats['total_exits_today']}',
                icon: Icons.logout_rounded,
                color: AppColors.exit,
              ),
            ),
          ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              Text(
                value,
                style: AppTextStyles.h2.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menus = [
      {
        'title': 'จัดการหมู่บ้าน',
        'icon': Icons.home_work_rounded,
        'color': AppColors.primary,
        'route': const VillageManagementScreen(),
      },
      {
        'title': 'จัดการผู้ใช้',
        'icon': Icons.people_rounded,
        'color': AppColors.accent,
        'route': const UserManagementScreen(),
      },
      {
        'title': 'รายงานสรุป',
        'icon': Icons.assessment_rounded,
        'color': AppColors.success,
        'route': const ReportsScreen(),
      },
      {
        'title': 'ตั้งค่า',
        'icon': Icons.settings_rounded,
        'color': AppColors.warning,
        'route': null, // TODO: Settings screen
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.2,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return _buildMenuCard(
          title: menu['title'] as String,
          icon: menu['icon'] as IconData,
          color: menu['color'] as Color,
          onTap: () {
            if (menu['route'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => menu['route'] as Widget),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${menu['title']} - Coming Soon'),
                  backgroundColor: AppColors.info,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 30.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text('ออกจากระบบ', style: AppTextStyles.h4),
        content: Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
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