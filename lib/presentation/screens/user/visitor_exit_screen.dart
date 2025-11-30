import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/print_helper.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/entry_log_repository.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';
import '../qr_scanner/qr_scanner_screen.dart';

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
  bool _isLoadingList = true;
  Map<String, dynamic>? _selectedVisitor;
  
  List<Map<String, dynamic>> _currentVisitors = [];

  // API Service & Repository
  late ApiService _apiService;
  late EntryLogRepository _entryLogRepository;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _entryLogRepository = EntryLogRepository(_apiService);
    _loadCurrentVisitors();
  }

  Future<void> _loadCurrentVisitors() async {
    setState(() => _isLoadingList = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('🔵 กำลังโหลดรายชื่อผู้อยู่ภายใน...');
      debugPrint('🔵 Village ID: ${authProvider.villageId}');
      
      final visitors = await _entryLogRepository.getCurrentVisitors(
        villageId: authProvider.villageId,
      );
      
      debugPrint('🟢 พบผู้อยู่ภายใน ${visitors.length} คน');
      
      setState(() {
        _currentVisitors = visitors.map((v) {
          // แปลง entry_time จาก String เป็น DateTime
          DateTime? entryTime;
          if (v['entry_time'] != null) {
            try {
              entryTime = DateTime.parse(v['entry_time'].toString());
            } catch (e) {
              entryTime = DateTime.now();
            }
          }
          
          return {
            ...v,
            'entry_time': entryTime ?? DateTime.now(),
            'visitor_name': v['visitor_name'] ?? v['full_name'] ?? 'ไม่ระบุ',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('🔴 โหลดรายชื่อไม่สำเร็จ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดรายชื่อได้: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingList = false);
      }
    }
  }

  List<Map<String, dynamic>> get filteredVisitors {
    if (_searchController.text.isEmpty) {
      return _currentVisitors;
    }
    
    final query = _searchController.text.toLowerCase().trim();
    
    return _currentVisitors.where((visitor) {
      final name = (visitor['visitor_name'] ?? '').toString().toLowerCase();
      final plate = (visitor['license_plate'] ?? '').toString().toLowerCase();
      final house = (visitor['house_number'] ?? '').toString().toLowerCase();
      final code = (visitor['qr_code'] ?? visitor['visitor_code'] ?? '').toString().toLowerCase();
      
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

  Future<void> _scanQRCode() async {
    try {
      final String? scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );

      if (scannedCode != null && scannedCode.isNotEmpty) {
        _searchController.text = scannedCode;
        setState(() {});

        if (filteredVisitors.length == 1) {
          setState(() {
            _selectedVisitor = filteredVisitors.first;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ พบผู้เข้า: ${filteredVisitors.first['visitor_name']}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (filteredVisitors.isEmpty) {
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
      
      final qrCode = _selectedVisitor!['qr_code'] ?? _selectedVisitor!['visitor_code'] ?? '';
      
      debugPrint('🔵 ========================================');
      debugPrint('🔵 เริ่มบันทึกผู้ออก...');
      debugPrint('🔵 QR Code: $qrCode');
      debugPrint('🔵 Visitor: ${_selectedVisitor!['visitor_name']}');
      debugPrint('🔵 ========================================');

      // เรียก API บันทึกออก
      final result = await _entryLogRepository.createExitSunmi(
        qrCode: qrCode,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      debugPrint('🟡 API Response: $result');

      if (result['success'] == true) {
        debugPrint('🟢 บันทึกออกสำเร็จ!');
        
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
      } else {
        debugPrint('🔴 บันทึกออกไม่สำเร็จ: ${result['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message'] ?? 'บันทึกไม่สำเร็จ'}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 ========================================');
      debugPrint('🔴 Error: $e');
      debugPrint('🔴 Stack Trace: $stackTrace');
      debugPrint('🔴 ========================================');
      
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
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedVisitor!['visitor_name'] ?? 'ไม่ระบุ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'ระยะเวลาอยู่ภายใน: $hours ชม. $minutes นาที',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text('กลับหน้าหลัก'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedVisitor = null;
                      _notesController.clear();
                      _searchController.clear();
                    });
                    _loadCurrentVisitors();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.exit,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text('บันทึกคนต่อไป', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('บันทึกผู้ออก', style: AppTextStyles.h4.copyWith(color: Colors.white)),
        backgroundColor: AppColors.exit,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadCurrentVisitors,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.exit,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อ, ทะเบียน, บ้านเลขที่...',
                        hintStyle: AppTextStyles.hint,
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: AppColors.textHint),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.exit),
                    onPressed: _scanQRCode,
                  ),
                ),
              ],
            ),
          ),

          // Count
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: AppColors.surfaceLight,
            child: Row(
              children: [
                Icon(Icons.people_rounded, size: 18.sp, color: AppColors.textSecondary),
                SizedBox(width: 8.w),
                Text(
                  'ผู้อยู่ภายในทั้งหมด',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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

          SizedBox(height: 8.h),

          // Visitors List
          Expanded(
            child: _isLoadingList
                ? LoadingWidget(message: 'กำลังโหลด...')
                : filteredVisitors.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.person_off_rounded,
                        title: 'ไม่พบผู้เข้าในระบบ',
                        subtitle: _searchController.text.isEmpty
                            ? 'ไม่มีผู้อยู่ในหมู่บ้านในขณะนี้'
                            : 'ไม่พบผลลัพธ์จากการค้นหา "${_searchController.text}"',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCurrentVisitors,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: filteredVisitors.length,
                          itemBuilder: (context, index) {
                            final visitor = filteredVisitors[index];
                            return _buildVisitorCard(visitor);
                          },
                        ),
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
    final isSelected = _selectedVisitor?['log_id'] == visitor['log_id'] ||
                       _selectedVisitor?['id'] == visitor['id'];
    
    DateTime entryTime = visitor['entry_time'] is DateTime 
        ? visitor['entry_time'] 
        : DateTime.now();
    
    final duration = DateTime.now().difference(entryTime);
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
                
                if (visitor['qr_code'] != null || visitor['visitor_code'] != null) ...[
                  _buildInfoRow(
                    Icons.qr_code_rounded,
                    'รหัส: ${visitor['qr_code'] ?? visitor['visitor_code']}',
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8.h),
                ],
                
                _buildInfoRow(
                  Icons.local_shipping_rounded,
                  '${visitor['vehicle_type'] ?? 'ไม่ระบุ'} ${visitor['license_plate'] ?? ''}',
                ),
                SizedBox(height: 8.h),
                _buildInfoRow(
                  Icons.home_rounded,
                  'บ้าน ${visitor['house_number'] ?? 'ไม่ระบุ'} ${visitor['resident_name'] != null ? '(${visitor['resident_name']})' : ''}',
                ),
                SizedBox(height: 8.h),
                _buildInfoRow(
                  Icons.access_time_rounded,
                  'เข้ามา $hours ชม. $minutes นาที',
                  color: hours >= 12 ? AppColors.warning : AppColors.success,
                ),
                
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
