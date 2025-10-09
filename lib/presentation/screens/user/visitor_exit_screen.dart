import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';

class VisitorExitScreen extends StatefulWidget {
  const VisitorExitScreen({Key? key}) : super(key: key);

  @override
  State<VisitorExitScreen> createState() => _VisitorExitScreenState();
}

class _VisitorExitScreenState extends State<VisitorExitScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSearching = false;
  bool _isLoading = false;
  Map<String, dynamic>? _selectedVisitor;

  // Mock current visitors
  final List<Map<String, dynamic>> _currentVisitors = [
    {
      'id': 1,
      'visitor_name': 'นายสมชาย ใจดี',
      'phone': '081-111-2222',
      'license_plate': 'กข-1234',
      'vehicle_type': 'รถยนต์',
      'house_number': '123/45',
      'resident_name': 'นายสมหมาย รักดี',
      'entry_time': DateTime.now().subtract(Duration(hours: 2)),
      'purpose': 'มาเยี่ยมบ้าน',
    },
    {
      'id': 2,
      'visitor_name': 'นางสมหญิง รักงาน',
      'phone': '081-333-4444',
      'license_plate': 'คค-5678',
      'vehicle_type': 'มอเตอร์ไซค์',
      'house_number': '234/56',
      'resident_name': 'นางสาวสมใจ ใจงาม',
      'entry_time': DateTime.now().subtract(Duration(hours: 1)),
      'purpose': 'ส่งของ',
    },
  ];

  List<Map<String, dynamic>> get filteredVisitors {
    if (_searchController.text.isEmpty) {
      return _currentVisitors;
    }
    final query = _searchController.text.toLowerCase();
    return _currentVisitors.where((visitor) {
      return visitor['visitor_name'].toLowerCase().contains(query) ||
          visitor['license_plate'].toLowerCase().contains(query) ||
          visitor['house_number'].toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleExit() async {
    if (_selectedVisitor == null) return;

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Update exit time in database via API

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColors.entry.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 50.sp,
                color: AppColors.exit,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'บันทึกสำเร็จ!',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.exit,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'บันทึกผู้ออกเรียบร้อยแล้ว',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'เสร็จสิ้น',
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to dashboard
            },
            type: ButtonType.error,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('บันทึกผู้ออก', style: AppTextStyles.appBarTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.exit, AppColors.exit.withValues(alpha:0.8)],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.background,
            child: CustomTextField(
              controller: _searchController,
              hint: 'ค้นหาด้วย ชื่อ, ทะเบียน, บ้านเลขที่',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Info Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: CustomCard(
              padding: EdgeInsets.all(12.w),
              color: AppColors.surfaceLight,
              child: Row(
                children: [
                  Icon(Icons.info_rounded, color: AppColors.info, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'เลือกผู้ที่ต้องการบันทึกออก',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${filteredVisitors.length} คน',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // Visitors List
          Expanded(
            child: _isSearching
                ? LoadingWidget(message: 'กำลังค้นหา...')
                : filteredVisitors.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.person_off_rounded,
                        title: 'ไม่พบผู้เข้าในระบบ',
                        subtitle: 'ลองค้นหาด้วยคำอื่น หรือตรวจสอบว่ามีผู้เข้าแล้วหรือไม่',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: filteredVisitors.length,
                        itemBuilder: (context, index) {
                          final visitor = filteredVisitors[index];
                          return _buildVisitorCard(visitor);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedVisitor != null
          ? Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: 'ยืนยันบันทึกออก',
                  onPressed: _handleExit,
                  isFullWidth: true,
                  isLoading: _isLoading,
                  icon: Icons.logout_rounded,
                  type: ButtonType.error,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildVisitorCard(Map<String, dynamic> visitor) {
    final isSelected = _selectedVisitor?['id'] == visitor['id'];
    final duration = DateTime.now().difference(visitor['entry_time']);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVisitor = isSelected ? null : visitor;
        });
      },
      child: CustomCard(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.exit : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: AppColors.exit.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.exit,
                        size: 26.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visitor['visitor_name'],
                            style: AppTextStyles.cardTitle,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 14.sp, color: AppColors.textHint),
                              SizedBox(width: 4.w),
                              Text(visitor['phone'], style: AppTextStyles.caption),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.exit,
                        size: 28.sp,
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 12.h),
                _buildInfoRow(
                  Icons.local_shipping_rounded,
                  '${visitor['vehicle_type']} ${visitor['license_plate']}',
                ),
                SizedBox(height: 8.h),
                _buildInfoRow(
                  Icons.home_rounded,
                  'บ้าน ${visitor['house_number']} (${visitor['resident_name']})',
                ),
                SizedBox(height: 8.h),
                _buildInfoRow(
                  Icons.access_time_rounded,
                  'เข้ามา $hours ชม. $minutes นาที',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: color ?? AppColors.textSecondary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}