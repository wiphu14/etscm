import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../providers/village_provider.dart';

class VillageManagementScreen extends StatefulWidget {
  const VillageManagementScreen({super.key});

  @override
  State<VillageManagementScreen> createState() => _VillageManagementScreenState();
}

class _VillageManagementScreenState extends State<VillageManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VillageProvider>().loadVillages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการหมู่บ้าน', style: AppTextStyles.appBarTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: Colors.white, size: 28.sp),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: Consumer<VillageProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return LoadingWidget(message: 'กำลังโหลดข้อมูล...');
          }

          if (provider.villages.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.home_work_rounded,
              title: 'ยังไม่มีหมู่บ้าน',
              subtitle: 'เพิ่มหมู่บ้านใหม่โดยกดปุ่ม + ด้านบน',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: provider.villages.length,
            itemBuilder: (context, index) {
              final village = provider.villages[index];
              return _buildVillageCard(village);
            },
          );
        },
      ),
    );
  }

  Widget _buildVillageCard(Map<String, dynamic> village) {
    return CustomCard(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  color: Colors.white,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      village['village_name'],
                      style: AppTextStyles.cardTitle,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'รหัส: ${village['village_code']}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20.sp, color: AppColors.primary),
                        SizedBox(width: 8.w),
                        Text('แก้ไข', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                        () => _showAddEditDialog(village: village),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20.sp, color: AppColors.error),
                        SizedBox(width: 8.w),
                        Text('ลบ', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(
                        Duration.zero,
                        () => _showDeleteDialog(village),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: AppColors.divider),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.location_on_rounded, village['address']),
          SizedBox(height: 8.h),
          _buildInfoRow(Icons.phone_rounded, village['contact_phone']),
          SizedBox(height: 8.h),
          _buildInfoRow(Icons.home_rounded, '${village['total_houses']} บ้าน'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.textSecondary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? village}) {
    final isEdit = village != null;
    final formKey = GlobalKey<FormState>();
    
    final codeController = TextEditingController(text: village?['village_code']);
    final nameController = TextEditingController(text: village?['village_name']);
    final addressController = TextEditingController(text: village?['address']);
    final provinceController = TextEditingController(text: village?['province']);
    final districtController = TextEditingController(text: village?['district']);
    final subDistrictController = TextEditingController(text: village?['sub_district']);
    final phoneController = TextEditingController(text: village?['contact_phone']);
    final housesController = TextEditingController(
      text: village?['total_houses']?.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit_rounded : Icons.add_rounded,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.w),
            Text(
              isEdit ? 'แก้ไขหมู่บ้าน' : 'เพิ่มหมู่บ้านใหม่',
              style: AppTextStyles.h4,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: codeController,
                  label: 'รหัสหมู่บ้าน',
                  hint: 'เช่น VL001',
                  prefixIcon: Icons.qr_code_rounded,
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกรหัส' : null,
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: nameController,
                  label: 'ชื่อหมู่บ้าน',
                  hint: 'เช่น หมู่บ้านสวนสยาม',
                  prefixIcon: Icons.home_work_rounded,
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: addressController,
                  label: 'ที่อยู่',
                  hint: 'เช่น 123 ถ.พหลโยธิน',
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 2,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: provinceController,
                        label: 'จังหวัด',
                        hint: 'จังหวัด',
                        prefixIcon: Icons.map_rounded,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: CustomTextField(
                        controller: districtController,
                        label: 'อำเภอ',
                        hint: 'อำเภอ',
                        prefixIcon: Icons.map_rounded,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: subDistrictController,
                  label: 'ตำบล',
                  hint: 'ตำบล',
                  prefixIcon: Icons.map_rounded,
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: phoneController,
                  label: 'เบอร์ติดต่อ',
                  hint: 'เช่น 02-1234567',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: housesController,
                  label: 'จำนวนบ้าน',
                  hint: 'เช่น 150',
                  prefixIcon: Icons.home_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          CustomButton(
            text: isEdit ? 'บันทึก' : 'เพิ่ม',
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final villageData = {
                  'village_code': codeController.text,
                  'village_name': nameController.text,
                  'address': addressController.text,
                  'province': provinceController.text,
                  'district': districtController.text,
                  'sub_district': subDistrictController.text,
                  'contact_phone': phoneController.text,
                  'total_houses': int.tryParse(housesController.text) ?? 0,
                };

                final provider = context.read<VillageProvider>();
                final success = isEdit
                    ? await provider.updateVillage(village['id'], villageData)
                    : await provider.addVillage(villageData);

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'แก้ไขข้อมูลสำเร็จ' : 'เพิ่มหมู่บ้านสำเร็จ'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            type: ButtonType.success,
            height: 45.h,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> village) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            SizedBox(width: 8.w),
            Text('ยืนยันการลบ', style: AppTextStyles.h4),
          ],
        ),
        content: Text(
          'คุณต้องการลบ "${village['village_name']}" ใช่หรือไม่?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          CustomButton(
            text: 'ลบ',
            onPressed: () async {
              final provider = context.read<VillageProvider>();
              final success = await provider.deleteVillage(village['id']);

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลบหมู่บ้านสำเร็จ'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            type: ButtonType.error,
            height: 45.h,
          ),
        ],
      ),
    );
  }
}