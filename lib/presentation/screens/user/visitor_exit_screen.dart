import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/print_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';
import '../qr_scanner/qr_scanner_screen.dart'; // เพิ่มบรรทัดนี้

class VisitorExitScreen extends StatefulWidget {
  const VisitorExitScreen({super.key});

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
      'visitor_code': 'VIS1728475800001',
      'visitor_name': 'นายสมชาย ใจดี',
      'phone': '081-111-2222',
      'license_plate': 'กข-1234',
      'vehicle_type': 'รถยนต์',
      'house_number': '123/45',
      'resident_name': 'นายสมหมาย รักดี',
      'entry_time': DateTime.now().subtract(const Duration(hours: 2)),
      'purpose': 'มาเยี่ยมบ้าน',
    },
    {
      'id': 2,
      'visitor_code': 'VIS1728475800002',
      'visitor_name': 'นางสมหญิง รักงาน',
      'phone': '081-333-4444',
      'license_plate': 'คค-5678',
      'vehicle_type': 'มอเตอร์ไซค์',
      'house_number': '234/56',
      'resident_name': 'นางสาวสมใจ ใจงาม',
      'entry_time': DateTime.now().subtract(const Duration(hours: 1)),
      'purpose': 'ส่งของ',
    },
  ];

  List<Map<String, dynamic>> get filteredVisitors {
    if (_searchController.text.isEmpty) {
      return _currentVisitors;
    }
    
    final query = _searchController.text.toLowerCase().trim();
    
    return _currentVisitors.where((visitor) {
      final name = (visitor['visitor_name'] ?? '').toString().toLowerCase();
      final plate = (visitor['license_plate'] ?? '').toString().toLowerCase();
      final house = (visitor['house_number'] ?? '').toString().toLowerCase();
      final code = (visitor['visitor_code'] ?? '').toString().toLowerCase();
      
      return name.contains(query) || 
             plate.contains(query) || 
             house.contains(query) ||
             code.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ✅ เพิ่มฟังก์ชัน Scan QR Code
  Future<void> _scanQRCode() async {
    try {
      final String? scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );

      if (scannedCode != null && scannedCode.isNotEmpty) {
        // ค้นหาผู้เข้าจากรหัส QR Code
        _searchController.text = scannedCode;
        setState(() {});

        // ถ้าเจอเพียงคนเดียว ให้เลือกอัตโนมัติ
        if (filteredVisitors.length == 1) {
          setState(() {
            _selectedVisitor = filteredVisitors.first;
          });

          // แสดง SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ พบผู้เข้า: ${filteredVisitors.first['visitor_name']}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (filteredVisitors.isEmpty) {
          // ไม่เจอ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ไม่พบรหัส QR Code นี้ในระบบ'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
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
    }
  }

  Future<void> _handleExit() async {
    if (_selectedVisitor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกผู้ที่ต้องการบันทึกออก'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final exitTime = DateTime.now();
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Update exit time in database via API

      // พิมพ์ใบยืนยันออก
      final printSuccess = await PrintHelper.printExitReceipt(
        visitorName: _selectedVisitor!['visitor_name'] ?? 'ไม่ระบุ',
        licensePlate: _selectedVisitor!['license_plate'] ?? 'ไม่ระบุ',
        houseNumber: _selectedVisitor!['house_number'] ?? 'ไม่ระบุ',
        entryTime: _selectedVisitor!['entry_time'] ?? DateTime.now(),
        exitTime: exitTime,
        villageName: authProvider.villageName ?? '',
        staffName: authProvider.fullName ?? '',
      );

      if (!printSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ บันทึกสำเร็จ แต่ไม่สามารถพิมพ์ได้'),
            backgroundColor: AppColors.warning,
          ),
        );
      }

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
    final duration = DateTime.now().difference(_selectedVisitor!['entry_time']);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

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
                color: AppColors.exit.withValues(alpha: 0.1),
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
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text(
                    '⏱️ ระยะเวลาที่อยู่',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$hours ชั่วโมง $minutes นาที',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.print_rounded, size: 16.sp, color: AppColors.primary),
                SizedBox(width: 4.w),
                Text(
                  'กำลังพิมพ์ใบยืนยัน...',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
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
    return Scaffold(
      appBar: AppBar(
        title: Text('บันทึกผู้ออก', style: AppTextStyles.appBarTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.exit, AppColors.exit.withValues(alpha: 0.8)],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // ✅ เพิ่มปุ่ม Scan QR Code ใน AppBar
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28.sp),
            onPressed: _scanQRCode,
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar พร้อมปุ่ม Scan
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.background,
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _searchController,
                    hint: 'ค้นหาด้วย ชื่อ, ทะเบียน, บ้านเลขที่, QR Code',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                SizedBox(width: 8.w),
                // ✅ ปุ่ม Scan QR Code
                Container(
                  height: 54.h,
                  width: 54.w,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _scanQRCode,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                  ),
                ),
              ],
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
                      'เลือกผู้ที่ต้องการบันทึกออก หรือ Scan QR Code',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
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
                        subtitle: _searchController.text.isEmpty
                            ? 'ไม่มีผู้อยู่ในหมู่บ้านในขณะนี้'
                            : 'ไม่พบผลลัพธ์จากการค้นหา "${_searchController.text}"',
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
                        color: AppColors.exit.withValues(alpha: 0.1),
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
                            visitor['visitor_name'] ?? 'ไม่ระบุ',
                            style: AppTextStyles.cardTitle,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 14.sp, color: AppColors.textHint),
                              SizedBox(width: 4.w),
                              Text(
                                visitor['phone'] ?? 'ไม่ระบุ',
                                style: AppTextStyles.caption,
                              ),
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
                
                // QR Code (ถ้ามี)
                if (visitor['visitor_code'] != null) ...[
                  _buildInfoRow(
                    Icons.qr_code_rounded,
                    'รหัส: ${visitor['visitor_code']}',
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8.h),
                ],
                
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
                  color: hours >= 12 ? AppColors.warning : AppColors.success,
                ),
                
                // แจ้งเตือนถ้าอยู่เกิน 12 ชั่วโมง
                if (hours >= 12) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: AppColors.warning,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'อยู่เกิน 12 ชั่วโมง',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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