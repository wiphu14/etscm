import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/village_repository.dart';
import '../../widgets/custom_card.dart';

class VillageManagementScreen extends StatefulWidget {
  const VillageManagementScreen({Key? key}) : super(key: key);

  @override
  State<VillageManagementScreen> createState() => _VillageManagementScreenState();
}

class _VillageManagementScreenState extends State<VillageManagementScreen> {
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = true;
  String? _errorMessage;

  late ApiService _apiService;
  late VillageRepository _villageRepository;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _villageRepository = VillageRepository(_apiService);
    _loadVillages();
  }

  Future<void> _loadVillages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔵 กำลังโหลดรายการหมู่บ้าน...');
      
      final villages = await _villageRepository.getAllVillages();
      
      debugPrint('🟢 โหลดหมู่บ้านสำเร็จ: ${villages.length} รายการ');

      if (mounted) {
        setState(() {
          _villages = List<Map<String, dynamic>>.from(villages);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🔴 โหลดหมู่บ้านไม่สำเร็จ: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'จัดการหมู่บ้าน',
          style: AppTextStyles.h4.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _loadVillages,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVillageDialog(),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text('กำลังโหลดข้อมูล...', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text('เกิดข้อผิดพลาด', style: AppTextStyles.h4),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                _errorMessage!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _loadVillages,
              icon: Icon(Icons.refresh_rounded),
              label: Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (_villages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text('ไม่พบข้อมูลหมู่บ้าน', style: AppTextStyles.h4),
            SizedBox(height: 8.h),
            Text(
              'กดปุ่ม + เพื่อเพิ่มหมู่บ้านใหม่',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVillages,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _villages.length,
        itemBuilder: (context, index) {
          final village = _villages[index];
          return _buildVillageCard(village);
        },
      ),
    );
  }

  Widget _buildVillageCard(Map<String, dynamic> village) {
    final isActive = village['is_active'] == true || village['status'] == 'active';
    
    return CustomCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      village['village_name'] ?? village['name'] ?? 'ไม่ระบุ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'รหัส: ${village['village_code'] ?? '-'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isActive ? 'ใช้งาน' : 'ปิดใช้งาน',
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.location_on_outlined,
                  label: 'ที่อยู่',
                  value: village['address'] ?? '-',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.phone_outlined,
                  label: 'โทรศัพท์',
                  value: village['contact_phone'] ?? '-',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.home_outlined,
                  label: 'จำนวนบ้าน',
                  value: '${village['total_houses'] ?? 0} หลัง',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditVillageDialog(village),
                icon: Icon(Icons.edit_rounded, size: 18.sp),
                label: Text('แก้ไข'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 8.w),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmDialog(village),
                icon: Icon(Icons.delete_rounded, size: 18.sp),
                label: Text('ลบ'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.textSecondary),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAddVillageDialog() {
    _showVillageFormDialog(null);
  }

  void _showEditVillageDialog(Map<String, dynamic> village) {
    _showVillageFormDialog(village);
  }

  void _showVillageFormDialog(Map<String, dynamic>? village) {
    final isEdit = village != null;
    final nameController = TextEditingController(text: village?['village_name'] ?? village?['name'] ?? '');
    final codeController = TextEditingController(text: village?['village_code'] ?? '');
    final addressController = TextEditingController(text: village?['address'] ?? '');
    final phoneController = TextEditingController(text: village?['contact_phone'] ?? '');
    final housesController = TextEditingController(text: '${village?['total_houses'] ?? ''}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(isEdit ? 'แก้ไขหมู่บ้าน' : 'เพิ่มหมู่บ้านใหม่', style: AppTextStyles.h4),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อหมู่บ้าน *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'รหัสหมู่บ้าน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'ที่อยู่',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'โทรศัพท์',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: housesController,
                decoration: InputDecoration(
                  labelText: 'จำนวนบ้าน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement save to API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEdit ? 'แก้ไขข้อมูลสำเร็จ' : 'เพิ่มหมู่บ้านสำเร็จ'),
                  backgroundColor: AppColors.success,
                ),
              );
              _loadVillages();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> village) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('ยืนยันการลบ', style: AppTextStyles.h4),
        content: Text(
          'คุณต้องการลบหมู่บ้าน "${village['village_name'] ?? village['name']}" ใช่หรือไม่?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ลบหมู่บ้านสำเร็จ'),
                  backgroundColor: AppColors.success,
                ),
              );
              _loadVillages();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
  }
}
