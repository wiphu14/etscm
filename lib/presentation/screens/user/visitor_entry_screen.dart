import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/print_helper.dart';
import '../../../core/utils/camera_helper.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../camera/camera_screen.dart';

class VisitorEntryScreen extends StatefulWidget {
  const VisitorEntryScreen({Key? key}) : super(key: key);

  @override
  State<VisitorEntryScreen> createState() => _VisitorEntryScreenState();
}

class _VisitorEntryScreenState extends State<VisitorEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _residentNameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  String _vehicleType = 'รถยนต์';
  bool _isLoading = false;
  bool _printReceipt = true;
  File? _photoFile;

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _licensePlateController.dispose();
    _houseNumberController.dispose();
    _residentNameController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      // สร้าง Visitor Code
      final visitorCode = 'VIS${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Upload รูปก่อน (ถ้ามี)
      String? photoUrl;
      if (_photoFile != null) {
        // TODO: Uncomment to use real API
        /*
        final apiService = ApiService();
        final visitorRepository = VisitorRepository(apiService);
        
        final uploadResult = await visitorRepository.uploadPhoto(
          photoFile: _photoFile!,
          visitorCode: visitorCode,
          useBase64: false, // true = Base64, false = Multipart
        );
        
        if (uploadResult['success']) {
          photoUrl = uploadResult['photo_url'];
        } else {
          // แสดง warning แต่ยังบันทึกข้อมูลต่อ
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ อัปโหลดรูปไม่สำเร็จ: ${uploadResult['message']}'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
        */
        
        // Mock: บันทึกรูปแบบ Local (สำหรับทดสอบ)
        final savedFile = await CameraHelper.saveImagePermanently(
          _photoFile!,
          visitorCode,
        );
        photoUrl = savedFile?.path;
      }

      // 2. บันทึกข้อมูลผู้เข้า
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 2));
      
      // TODO: Save to database with photoUrl
      /*
      final entryRepository = EntryLogRepository(apiService);
      final result = await entryRepository.createEntry(
        visitorData: {
          'visitor_code': visitorCode,
          'full_name': _nameController.text,
          'id_card': _idCardController.text,
          'phone': _phoneController.text,
          'vehicle_type': _vehicleType,
          'license_plate': _licensePlateController.text,
          'photo_url': photoUrl, // บันทึก URL รูป
        },
        entryData: {
          'village_id': authProvider.villageId,
          'user_id': authProvider.userId,
          'house_number': _houseNumberController.text,
          'resident_name': _residentNameController.text,
          'purpose': _purposeController.text,
          'notes': _notesController.text,
        },
      );
      */
      
      // 3. พิมพ์ใบผ่าน (ถ้าเปิด)
      if (_printReceipt) {
        final printSuccess = await PrintHelper.printEntryPass(
          visitorName: _nameController.text,
          phone: _phoneController.text,
          licensePlate: _licensePlateController.text,
          vehicleType: _vehicleType,
          houseNumber: _houseNumberController.text,
          residentName: _residentNameController.text,
          purpose: _purposeController.text,
          entryTime: DateTime.now(),
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
      }

      if (mounted) {
        _showSuccessDialog(photoUploaded: photoUrl != null);
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

  void _showSuccessDialog({bool photoUploaded = false}) {
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
                color: AppColors.entry.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 50.sp,
                color: AppColors.entry,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'บันทึกสำเร็จ!',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.entry,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'บันทึกผู้เข้าเรียบร้อยแล้ว',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_printReceipt) ...[
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.print_rounded, size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Text(
                    'กำลังพิมพ์ใบผ่าน...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            if (_photoFile != null) ...[
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    photoUploaded ? Icons.cloud_done_rounded : Icons.check_circle_outline,
                    size: 16.sp,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    photoUploaded ? 'อัปโหลดรูปสำเร็จ' : 'บันทึกรูปภาพแล้ว',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          CustomButton(
            text: 'เสร็จสิ้น',
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to dashboard
            },
            type: ButtonType.success,
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
        title: Text('บันทึกผู้เข้า', style: AppTextStyles.appBarTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.entry, AppColors.entry.withOpacity(0.8)],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              CustomCard(
                padding: EdgeInsets.all(16.w),
                color: AppColors.surfaceLight,
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: AppColors.primary, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เวลาเข้า: ${DateFormat('HH:mm น.').format(DateTime.now())}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'หมู่บ้าน: ${authProvider.villageName}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Visitor Information
              Text('ข้อมูลผู้มาติดต่อ', style: AppTextStyles.h4),
              SizedBox(height: 16.h),

              // Photo Section
              _buildPhotoSection(),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _nameController,
                label: 'ชื่อ-นามสกุล *',
                hint: 'กรอกชื่อ-นามสกุล',
                prefixIcon: Icons.person_rounded,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
              ),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _idCardController,
                label: 'เลขบัตรประชาชน',
                hint: 'x-xxxx-xxxxx-xx-x',
                prefixIcon: Icons.badge_rounded,
                keyboardType: TextInputType.number,
                maxLength: 13,
              ),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _phoneController,
                label: 'เบอร์โทร *',
                hint: '0xx-xxx-xxxx',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'กรุณากรอกเบอร์โทร' : null,
              ),

              SizedBox(height: 24.h),

              // Vehicle Information
              Text('ข้อมูลยานพาหนะ', style: AppTextStyles.h4),
              SizedBox(height: 16.h),

              // Vehicle Type Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ประเภทยานพาหนะ *', style: AppTextStyles.label),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVehicleTypeCard('รถยนต์', Icons.directions_car_rounded),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildVehicleTypeCard('มอเตอร์ไซค์', Icons.two_wheeler_rounded),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _licensePlateController,
                label: 'ทะเบียนรถ *',
                hint: 'เช่น กข-1234',
                prefixIcon: Icons.local_shipping_rounded,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'กรุณากรอกทะเบียน' : null,
              ),

              SizedBox(height: 24.h),

              // Destination
              Text('ข้อมูลการติดต่อ', style: AppTextStyles.h4),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _houseNumberController,
                label: 'บ้านเลขที่ *',
                hint: 'เช่น 123/45',
                prefixIcon: Icons.home_rounded,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'กรุณากรอกบ้านเลขที่' : null,
              ),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _residentNameController,
                label: 'ชื่อเจ้าบ้าน *',
                hint: 'กรอกชื่อเจ้าบ้าน',
                prefixIcon: Icons.person_pin_rounded,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'กรุณากรอกชื่อเจ้าบ้าน' : null,
              ),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _purposeController,
                label: 'วัตถุประสงค์ *',
                hint: 'เช่น มาเยี่ยมบ้าน',
                prefixIcon: Icons.comment_rounded,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'กรุณากรอกวัตถุประสงค์' : null,
              ),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _notesController,
                label: 'หมายเหตุ',
                hint: 'หมายเหตุเพิ่มเติม (ถ้ามี)',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
              ),

              SizedBox(height: 24.h),

              // Print Receipt Option
              CustomCard(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(Icons.print_rounded, color: AppColors.primary, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'พิมพ์ใบผ่านหลังบันทึก',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _printReceipt,
                      onChanged: (value) => setState(() => _printReceipt = value),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Save Button
              CustomButton(
                text: 'บันทึกผู้เข้า',
                onPressed: _handleSave,
                isFullWidth: true,
                isLoading: _isLoading,
                icon: Icons.save_rounded,
                type: ButtonType.success,
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('รูปถ่าย', style: AppTextStyles.label),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'แนะนำ',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.info,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        CustomCard(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Photo Preview
              GestureDetector(
                onTap: () => _showPhotoOptions(),
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _photoFile != null ? AppColors.primary : AppColors.border,
                      width: _photoFile != null ? 2 : 1,
                    ),
                    image: _photoFile != null
                        ? DecorationImage(
                            image: FileImage(_photoFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _photoFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              size: 32.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'เพิ่มรูป',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              
              // Buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _takePhoto(),
                      icon: Icon(Icons.camera_alt_rounded, size: 20.sp),
                      label: Text('ถ่ายรูป'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    OutlinedButton.icon(
                      onPressed: () => _pickFromGallery(),
                      icon: Icon(Icons.photo_library_rounded, size: 20.sp),
                      label: Text('เลือกจากคลัง'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    if (_photoFile != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _photoFile = null),
                        icon: Icon(Icons.delete_rounded, size: 18.sp),
                        label: Text('ลบรูป'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text('เลือกรูปภาพ', style: AppTextStyles.h4),
            SizedBox(height: 20.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 24.sp),
              ),
              title: Text('ถ่ายรูปด้วยกล้อง', style: AppTextStyles.bodyMedium),
              subtitle: Text('เปิดกล้องเพื่อถ่ายรูป', style: AppTextStyles.caption),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            SizedBox(height: 8.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.photo_library_rounded, color: AppColors.accent, size: 24.sp),
              ),
              title: Text('เลือกจากคลัง', style: AppTextStyles.bodyMedium),
              subtitle: Text('เลือกรูปจาก Gallery', style: AppTextStyles.caption),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (_photoFile != null) ...[
              SizedBox(height: 8.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.delete_rounded, color: AppColors.error, size: 24.sp),
                ),
                title: Text('ลบรูป', style: AppTextStyles.bodyMedium),
                subtitle: Text('ลบรูปที่เลือก', style: AppTextStyles.caption),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoFile = null);
                },
              ),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final file = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (file != null) {
      setState(() => _photoFile = file);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await CameraHelper.pickFromGallery();
    if (file != null) {
      // บีบอัดรูป
      final compressed = await CameraHelper.compressImage(file);
      setState(() => _photoFile = compressed ?? file);
    }
  }

  Widget _buildVehicleTypeCard(String type, IconData icon) {
    final isSelected = _vehicleType == type;

    return GestureDetector(
      onTap: () => setState(() => _vehicleType = type),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(height: 8.h),
            Text(
              type,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}