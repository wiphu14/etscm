import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../../providers/village_provider.dart';

class VillageManagementScreen extends StatefulWidget {
  const VillageManagementScreen({Key? key}) : super(key: key);

  @override
  State<VillageManagementScreen> createState() => _VillageManagementScreenState();
}

class _VillageManagementScreenState extends State<VillageManagementScreen> {
  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลหลังจาก build เสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVillages();
    });
  }

  Future<void> _loadVillages() async {
    debugPrint('🔵 VillageManagementScreen._loadVillages() เริ่มทำงาน...');
    await context.read<VillageProvider>().loadVillages();
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
      body: Consumer<VillageProvider>(
        builder: (context, villageProvider, child) {
          debugPrint('🟡 Consumer rebuild - isLoading: ${villageProvider.isLoading}, villages: ${villageProvider.villages.length}');
          
          if (villageProvider.isLoading) {
            return _buildLoading();
          }

          if (villageProvider.errorMessage != null && villageProvider.villages.isEmpty) {
            return _buildError(villageProvider.errorMessage!);
          }

          if (villageProvider.villages.isEmpty) {
            return _buildEmpty();
          }

          return _buildVillageList(villageProvider.villages);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVillageDialog(),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16.h),
          Text('กำลังโหลดข้อมูล...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
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
              message,
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

  Widget _buildEmpty() {
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
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _loadVillages,
            icon: Icon(Icons.refresh_rounded),
            label: Text('รีเฟรช'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVillageList(List<Map<String, dynamic>> villages) {
    return RefreshIndicator(
      onRefresh: _loadVillages,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: villages.length,
        itemBuilder: (context, index) {
          final village = villages[index];
          return _buildVillageCard(village);
        },
      ),
    );
  }

  Widget _buildVillageCard(Map<String, dynamic> village) {
    final isActive = village['is_active'] == true || 
                     village['is_active'] == 1 ||
                     village['status'] == 'active';
    
    final villageName = village['village_name'] ?? village['name'] ?? 'ไม่ระบุ';
    final villageCode = village['village_code'] ?? '-';
    final address = village['address'] ?? '-';
    final phone = village['contact_phone'] ?? village['phone'] ?? '-';
    final totalHouses = village['total_houses'] ?? 0;
    final villageId = village['id'] ?? village['village_id'];
    
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
                      villageName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'รหัส: $villageCode',
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
                  value: address,
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
                  value: phone,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.home_outlined,
                  label: 'จำนวนบ้าน',
                  value: '$totalHouses หลัง',
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
    final phoneController = TextEditingController(text: village?['contact_phone'] ?? village?['phone'] ?? '');
    final housesController = TextEditingController(text: '${village?['total_houses'] ?? ''}');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final villageData = {
                'village_name': nameController.text,
                'village_code': codeController.text,
                'address': addressController.text,
                'contact_phone': phoneController.text,
                'total_houses': int.tryParse(housesController.text) ?? 0,
              };

              Navigator.pop(dialogContext);

              final villageProvider = context.read<VillageProvider>();
              bool success;

              if (isEdit) {
                final id = village['id'] ?? village['village_id'];
                success = await villageProvider.updateVillage(id, villageData);
              } else {
                success = await villageProvider.addVillage(villageData);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? (isEdit ? 'แก้ไขข้อมูลสำเร็จ' : 'เพิ่มหมู่บ้านสำเร็จ')
                      : (villageProvider.errorMessage ?? 'เกิดข้อผิดพลาด')),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> village) {
    final villageName = village['village_name'] ?? village['name'] ?? 'ไม่ระบุ';
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('ยืนยันการลบ', style: AppTextStyles.h4),
        content: Text(
          'คุณต้องการลบหมู่บ้าน "$villageName" ใช่หรือไม่?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              final villageProvider = context.read<VillageProvider>();
              final id = village['id'] ?? village['village_id'];
              final success = await villageProvider.deleteVillage(id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? 'ลบหมู่บ้านสำเร็จ'
                      : (villageProvider.errorMessage ?? 'เกิดข้อผิดพลาด')),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
  }
}