import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/entry_log_repository.dart';
import '../../widgets/custom_card.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'visitor_entry_screen.dart';
import 'visitor_exit_screen.dart';
import 'visitor_history_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  // Statistics
  Map<String, dynamic> _todayStats = {
    'total_entries': 0,
    'total_exits': 0,
    'current_visitors': 0,
  };

  // Recent activities (ทั้งเข้าและออก)
  List<Map<String, dynamic>> _recentActivities = [];
  
  bool _isLoading = true;

  // API Service & Repository
  late ApiService _apiService;
  late EntryLogRepository _entryLogRepository;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _entryLogRepository = EntryLogRepository(_apiService);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('🔵 กำลังโหลดข้อมูล Dashboard...');
      debugPrint('🔵 Village ID: ${authProvider.villageId}');

      // ============================================
      // เรียก API Dashboard ใหม่
      // ============================================
      final response = await _apiService.get(
        '/sunmi/dashboard.php',
        queryParameters: {
          'village_id': authProvider.villageId,
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
      );

      debugPrint('🟢 Dashboard Response: ${response.data}');

      if (mounted && response.statusCode == 200) {
        final data = response.data;
        
        if (data['success'] == true && data['data'] != null) {
          final dashboardData = data['data'];
          final stats = dashboardData['stats'] ?? {};
          final activities = dashboardData['recent_activities'] ?? [];
          
          setState(() {
            _todayStats = {
              'total_entries': stats['today_entries'] ?? stats['total_entries'] ?? 0,
              'total_exits': stats['today_exits'] ?? stats['total_exits'] ?? 0,
              'current_visitors': stats['current_inside'] ?? stats['current_visitors'] ?? 0,
            };
            
            _recentActivities = (activities as List).map((activity) {
              DateTime? activityTime;
              if (activity['activity_time'] != null) {
                try {
                  activityTime = DateTime.parse(activity['activity_time'].toString());
                } catch (e) {
                  activityTime = DateTime.now();
                }
              }
              
              return {
                'log_id': activity['log_id'],
                'visitor_name': activity['visitor_name'] ?? 'ไม่ระบุ',
                'license_plate': activity['license_plate'] ?? 'ไม่ระบุ',
                'house_number': activity['house_number'] ?? 'ไม่ระบุ',
                'activity_time': activityTime ?? DateTime.now(),
                'activity_type': activity['activity_type'] ?? 'entry',
                'status': activity['status'] ?? 'inside',
              };
            }).toList();
          });
          
          debugPrint('🟢 Stats: $_todayStats');
          debugPrint('🟢 Activities: ${_recentActivities.length} รายการ');
        } else {
          // Fallback to old API
          await _loadDashboardDataFallback();
        }
      } else {
        // Fallback to old API
        await _loadDashboardDataFallback();
      }
    } catch (e) {
      debugPrint('🔴 โหลดข้อมูล Dashboard ไม่สำเร็จ: $e');
      // Try fallback
      await _loadDashboardDataFallback();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fallback method ถ้า API ใหม่ยังไม่พร้อม
  Future<void> _loadDashboardDataFallback() async {
    try {
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('🟡 Using fallback API...');

      // โหลดสถิติ
      final stats = await _entryLogRepository.getDashboardStats(
        villageId: authProvider.villageId,
        date: DateTime.now(),
      );
      
      debugPrint('🟢 Stats (fallback): $stats');

      // โหลดรายการล่าสุด
      final logs = await _entryLogRepository.getLogsByDate(
        date: DateTime.now(),
        villageId: authProvider.villageId,
      );
      
      debugPrint('🟢 Recent Logs (fallback): ${logs.length} รายการ');

      if (mounted) {
        setState(() {
          _todayStats = {
            'total_entries': stats['today_entries'] ?? stats['total_entries'] ?? 0,
            'total_exits': stats['today_exits'] ?? stats['total_exits'] ?? 0,
            'current_visitors': stats['current_inside'] ?? stats['current_visitors'] ?? 0,
          };
          
          // แปลง logs เป็น activities (ทั้งเข้าและออก)
          _recentActivities = [];
          
          for (var log in logs.take(10)) {
            DateTime? entryTime;
            DateTime? exitTime;
            
            if (log['entry_time'] != null) {
              try {
                entryTime = DateTime.parse(log['entry_time'].toString());
              } catch (e) {
                entryTime = null;
              }
            }
            
            if (log['exit_time'] != null) {
              try {
                exitTime = DateTime.parse(log['exit_time'].toString());
              } catch (e) {
                exitTime = null;
              }
            }
            
            // เพิ่มรายการเข้า
            if (entryTime != null) {
              _recentActivities.add({
                'log_id': log['log_id'],
                'visitor_name': log['visitor_name'] ?? log['full_name'] ?? 'ไม่ระบุ',
                'license_plate': log['license_plate'] ?? 'ไม่ระบุ',
                'house_number': log['house_number'] ?? 'ไม่ระบุ',
                'activity_time': entryTime,
                'activity_type': 'entry',
                'status': log['status'] ?? 'inside',
              });
            }
            
            // เพิ่มรายการออก (ถ้ามี)
            if (exitTime != null) {
              _recentActivities.add({
                'log_id': log['log_id'],
                'visitor_name': log['visitor_name'] ?? log['full_name'] ?? 'ไม่ระบุ',
                'license_plate': log['license_plate'] ?? 'ไม่ระบุ',
                'house_number': log['house_number'] ?? 'ไม่ระบุ',
                'activity_time': exitTime,
                'activity_type': 'exit',
                'status': 'exited',
              });
            }
          }
          
          // เรียงตามเวลาล่าสุด
          _recentActivities.sort((a, b) {
            final timeA = a['activity_time'] as DateTime;
            final timeB = b['activity_time'] as DateTime;
            return timeB.compareTo(timeA);
          });
          
          // เอาแค่ 10 รายการล่าสุด
          if (_recentActivities.length > 10) {
            _recentActivities = _recentActivities.take(10).toList();
          }
        });
      }
    } catch (e) {
      debugPrint('🔴 Fallback also failed: $e');
    }
  }

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
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),

                          // Quick Actions
                          _buildQuickActions(),

                          SizedBox(height: 24.h),

                          // Today Statistics
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('สถิติวันนี้', style: AppTextStyles.h4),
                              Text(
                                DateFormat('d MMM yyyy', 'th').format(DateTime.now()),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _buildTodayStats(),

                          SizedBox(height: 24.h),

                          // Recent Activities
                          _buildRecentActivitiesHeader(),
                          SizedBox(height: 12.h),
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _buildRecentActivities(),
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
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
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
                      'สวัสดี, ${authProvider.fullName ?? 'ผู้ใช้'}',
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
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            authProvider.villageName ?? '',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'บันทึกเข้า',
            icon: Icons.login_rounded,
            color: AppColors.entry,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VisitorEntryScreen()),
              );
              _loadDashboardData(); // Refresh after return
            },
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildActionCard(
            title: 'บันทึกออก',
            icon: Icons.logout_rounded,
            color: AppColors.exit,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VisitorExitScreen()),
              );
              _loadDashboardData(); // Refresh after return
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Column(
          children: [
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
              color: color.withValues(alpha: 0.1),
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
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VisitorHistoryScreen()),
            );
            _loadDashboardData(); // Refresh after return
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
    if (_recentActivities.isEmpty) {
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
                  'ยังไม่มีกิจกรรมวันนี้',
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
      children: _recentActivities.take(5).map((activity) {
        return _buildActivityCard(activity);
      }).toList(),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final isEntry = activity['activity_type'] == 'entry';
    final statusColor = isEntry ? AppColors.entry : AppColors.exit;
    final activityTime = activity['activity_time'] as DateTime;
    final timeStr = DateFormat('HH:mm').format(activityTime);
    final timeAgo = _getTimeAgo(activityTime);

    return CustomCard(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
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
                  activity['visitor_name'] ?? 'ไม่ระบุ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${activity['license_plate']} • บ้าน ${activity['house_number']}',
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
                  color: statusColor.withValues(alpha: 0.1),
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
                timeStr,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
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
    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('ออกจากระบบ', style: AppTextStyles.h4),
        content: Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ยกเลิก', style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
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