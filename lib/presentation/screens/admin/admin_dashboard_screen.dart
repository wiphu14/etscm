import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/entry_log_repository.dart';
import '../../../data/repositories/village_repository.dart';
import '../../widgets/custom_card.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'village_management_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Statistics - จะโหลดจาก API
  int _totalVillages = 0;
  int _totalUsers = 0;
  int _totalVisitorsToday = 0;
  int _totalEntriesToday = 0;
  int _totalExitsToday = 0;

  bool _isLoading = true;
  String? _errorMessage;

  // API Service & Repository
  late ApiService _apiService;
  late EntryLogRepository _entryLogRepository;
  late VillageRepository _villageRepository;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _entryLogRepository = EntryLogRepository(_apiService);
    _villageRepository = VillageRepository(_apiService);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔵 กำลังโหลดข้อมูล Admin Dashboard...');

      // โหลดรายการหมู่บ้าน
      List villages = [];
      try {
        villages = await _villageRepository.getAllVillages();
        debugPrint('🟢 Villages: ${villages.length}');
      } catch (e) {
        debugPrint('🔴 Error loading villages: $e');
      }

      // โหลดสถิติจาก API
      Map<String, dynamic> stats = {};
      try {
        stats = await _entryLogRepository.getDashboardStats(
          date: DateTime.now(),
        );
        debugPrint('🟢 Stats: $stats');
      } catch (e) {
        debugPrint('🔴 Error loading stats: $e');
      }

      if (mounted) {
        setState(() {
          _totalVillages = villages.length;
          _totalUsers = stats['total_users'] ?? 0;
          _totalVisitorsToday = stats['current_inside'] ?? stats['current_visitors'] ?? 0;
          _totalEntriesToday = stats['today_entries'] ?? stats['total_entries'] ?? 0;
          _totalExitsToday = stats['today_exits'] ?? stats['total_exits'] ?? 0;
          _isLoading = false;
        });
      }

      debugPrint('🟢 Dashboard Data Loaded:');
      debugPrint('   - Villages: $_totalVillages');
      debugPrint('   - Users: $_totalUsers');
      debugPrint('   - Current Inside: $_totalVisitorsToday');
      debugPrint('   - Entries Today: $_totalEntriesToday');
      debugPrint('   - Exits Today: $_totalExitsToday');

    } catch (e) {
      debugPrint('🔴 โหลดข้อมูล Dashboard ไม่สำเร็จ: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

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
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),

                          // Statistics Cards
                          Text(
                            'สถิติวันนี้',
                            style: AppTextStyles.h4,
                          ),
                          SizedBox(height: 12.h),
                          _isLoading
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.h),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _buildStatisticsGrid(),

                          SizedBox(height: 20.h),

                          // Menu Section
                          Text(
                            'เมนูจัดการ',
                            style: AppTextStyles.h4,
                          ),
                          SizedBox(height: 12.h),
                          _buildMenuGrid(),
                          
                          SizedBox(height: 20.h),
                        ],
                      ),
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
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
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
              size: 26.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สวัสดี, ${authProvider.fullName ?? 'ผู้ดูแลระบบ'}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  authProvider.villageName ?? 'ผู้ดูแลระบบ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(),
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 22.sp,
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
                title: 'หมู่บ้าน',
                value: '$_totalVillages',
                icon: Icons.home_work_rounded,
                color: AppColors.primary,
                onTap: () {
                  // ไปหน้าจัดการหมู่บ้าน
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VillageManagementScreen()),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildStatCard(
                title: 'ผู้ใช้งาน',
                value: '$_totalUsers',
                icon: Icons.people_rounded,
                color: AppColors.accent,
                onTap: () {
                  // ไปหน้าจัดการผู้ใช้
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _buildStatCard(
          title: 'ผู้อยู่ภายใน',
          value: '$_totalVisitorsToday',
          icon: Icons.person_rounded,
          color: AppColors.info,
          isFullWidth: true,
          onTap: () {
            // แสดงรายละเอียดผู้อยู่ภายใน
            _showCurrentVisitorsDialog();
          },
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'เข้า',
                value: '$_totalEntriesToday',
                icon: Icons.login_rounded,
                color: AppColors.success,
                onTap: () {
                  // แสดงรายละเอียดผู้เข้าวันนี้
                  _showTodayEntriesDialog();
                },
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildStatCard(
                title: 'ออก',
                value: '$_totalExitsToday',
                icon: Icons.logout_rounded,
                color: AppColors.warning,
                onTap: () {
                  // แสดงรายละเอียดผู้ออกวันนี้
                  _showTodayExitsDialog();
                },
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
    bool isFullWidth = false,
    VoidCallback? onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTextStyles.h4.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
          // แสดงลูกศรบอกว่าคลิกได้
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: 20.sp,
            ),
        ],
      ),
    );
  }

  // Dialog แสดงผู้อยู่ภายใน
  void _showCurrentVisitorsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.person_rounded, color: AppColors.info),
            SizedBox(width: 8.w),
            Text('ผู้อยู่ภายใน', style: AppTextStyles.h4),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ขณะนี้มีผู้อยู่ภายใน $_totalVisitorsToday คน',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              'รวมทุกหมู่บ้าน',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด'),
          ),
        ],
      ),
    );
  }

  // Dialog แสดงผู้เข้าวันนี้
  void _showTodayEntriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.login_rounded, color: AppColors.success),
            SizedBox(width: 8.w),
            Text('สถิติเข้าวันนี้', style: AppTextStyles.h4),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'วันนี้มีผู้เข้าทั้งหมด $_totalEntriesToday คน',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              'นับตั้งแต่ 00:00 น.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด'),
          ),
        ],
      ),
    );
  }

  // Dialog แสดงผู้ออกวันนี้
  void _showTodayExitsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.warning),
            SizedBox(width: 8.w),
            Text('สถิติออกวันนี้', style: AppTextStyles.h4),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'วันนี้มีผู้ออกทั้งหมด $_totalExitsToday คน',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              'นับตั้งแต่ 00:00 น.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    // เฉพาะ 2 เมนูที่ต้องการ
    final menus = [
      {
        'title': 'จัดการหมู่บ้าน',
        'icon': Icons.home_work_rounded,
        'color': AppColors.primary,
        'screen': const VillageManagementScreen(),
      },
      {
        'title': 'จัดการผู้ใช้',
        'icon': Icons.people_rounded,
        'color': AppColors.accent,
        'screen': const UserManagementScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 1.6,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return _buildMenuCard(
          title: menu['title'] as String,
          icon: menu['icon'] as IconData,
          color: menu['color'] as Color,
          onTap: () async {
            if (menu['screen'] != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => menu['screen'] as Widget),
              );
              // Refresh data when returning
              _loadDashboardData();
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
      padding: EdgeInsets.all(12.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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