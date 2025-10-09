import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/print_helper.dart';
import '../../../core/utils/camera_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../camera/camera_screen.dart';

class VisitorEntryScreen extends StatefulWidget {
  const VisitorEntryScreen({super.key});

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
  final _purposeOtherController = TextEditingController();
  final _notesController = TextEditingController();

  String _vehicleType = 'รถยนต์';
  bool _isLoading = false;
  bool _printReceipt = true;
  
  String? _selectedPurpose;
  
  final List<String> _purposeOptions = [
    'นิติบุคคล',
    'สำนักงานขาย',
    'พบลูกบ้าน',
    'ผู้รับเหมา',
    'ส่งของ',
    'อื่นๆ',
  ];
  
  final List<File?> _photoFiles = [null, null, null];
  String? _generatedQRCode;

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _licensePlateController.dispose();
    _houseNumberController.dispose();
    _residentNameController.dispose();
    _purposeOtherController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final visitorCode = 'VIS$timestamp';
      
      _generatedQRCode = visitorCode;
      
      // เตรียมข้อมูลวัตถุประสงค์
      String finalPurpose = 'ไม่ระบุ';
      
      if (_selectedPurpose != null) {
        if (_selectedPurpose == 'อื่นๆ' && _purposeOtherController.text.isNotEmpty) {
          finalPurpose = _purposeOtherController.text;
        } else if (_selectedPurpose == 'อื่นๆ') {
          finalPurpose = 'อื่นๆ';
        } else {
          finalPurpose = _selectedPurpose!;
        }
      }
      
      // Upload รูปทั้งหมด
      List<String?> photoUrls = [];
      for (int i = 0; i < _photoFiles.length; i++) {
        if (_photoFiles[i] != null) {
          final savedFile = await CameraHelper.saveImagePermanently(
            _photoFiles[i]!,
            '${visitorCode}_$i',
          );
          photoUrls.add(savedFile?.path);
        } else {
          photoUrls.add(null);
        }
      }

      await Future.delayed(const Duration(seconds: 2));
      
      // พิมพ์ใบผ่าน
      if (_printReceipt) {
        final printSuccess = await PrintHelper.printEntryPassWithQR(
          visitorName: _nameController.text.isEmpty ? 'ไม่ระบุ' : _nameController.text,
          phone: _phoneController.text.isEmpty ? 'ไม่ระบุ' : _phoneController.text,
          licensePlate: _licensePlateController.text.isEmpty ? 'ไม่ระบุ' : _licensePlateController.text,
          vehicleType: _vehicleType,
          houseNumber: _houseNumberController.text.isEmpty ? 'ไม่ระบุ' : _houseNumberController.text,
          residentName: _residentNameController.text.isEmpty ? 'ไม่ระบุ' : _residentNameController.text,
          purpose: finalPurpose,
          entryTime: DateTime.now(),
          villageName: authProvider.villageName ?? '',
          staffName: authProvider.fullName ?? '',
          qrCode: visitorCode,
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
        _showSuccessDialog(
          photoCount: _photoFiles.where((f) => f != null).length,
        );
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

  void _showSuccessDialog({int photoCount = 0}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70.w,
                  height: 70.h,
                  decoration: BoxDecoration(
                    color: AppColors.entry.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 40.sp,
                    color: AppColors.entry,
                  ),
                ),
                SizedBox(height: 12.h),
                
                Text(
                  'บันทึกสำเร็จ!',
                  style: AppTextStyles.h3.copyWith(color: AppColors.entry),
                ),
                SizedBox(height: 6.h),
                
                Text(
                  'บันทึกผู้เข้าเรียบร้อยแล้ว',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (_generatedQRCode != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: _generatedQRCode!,
                          version: QrVersions.auto,
                          size: 120.w,
                          backgroundColor: Colors.white,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'รหัส: $_generatedQRCode',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (_printReceipt || photoCount > 0) ...[
                  SizedBox(height: 10.h),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_printReceipt)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print_rounded, size: 14.sp, color: AppColors.primary),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                'กำลังพิมพ์ใบผ่าน...',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_printReceipt && photoCount > 0) SizedBox(height: 6.h),
                      if (photoCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_rounded,
                              size: 14.sp,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                'บันทึก $photoCount รูปภาพแล้ว',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: CustomButton(
              text: 'เสร็จสิ้น',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              type: ButtonType.success,
              isFullWidth: true,
            ),
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
              colors: [AppColors.entry, AppColors.entry.withValues(alpha: 0.8)],
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

              Text('ข้อมูลผู้มาติดต่อ', style: AppTextStyles.h4),
              SizedBox(height: 16.h),

              _buildPhotoSection(),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _nameController,
                label: 'ชื่อ-นามสกุล',
                hint: 'กรอกชื่อ-นามสกุล',
                prefixIcon: Icons.person_rounded,
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
                label: 'เบอร์โทร',
                hint: '0xx-xxx-xxxx',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: 24.h),

              Text('ข้อมูลยานพาหนะ', style: AppTextStyles.h4),
              SizedBox(height: 16.h),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ประเภทยานพาหนะ', style: AppTextStyles.label),
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
                label: 'ทะเบียนรถ',
                hint: 'เช่น กข-1234',
                prefixIcon: Icons.local_shipping_rounded,
              ),

              SizedBox(height: 24.h),

              Text('ข้อมูลการติดต่อ', style: AppTextStyles.h4),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _houseNumberController,
                label: 'บ้านเลขที่',
                hint: 'เช่น 123/45',
                prefixIcon: Icons.home_rounded,
              ),
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _residentNameController,
                label: 'ชื่อเจ้าบ้าน',
                hint: 'กรอกชื่อเจ้าบ้าน',
                prefixIcon: Icons.person_pin_rounded,
              ),
              SizedBox(height: 16.h),

              _buildPurposeDropdown(),
              
              if (_selectedPurpose == 'อื่นๆ') ...[
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _purposeOtherController,
                  label: 'ระบุวัตถุประสงค์',
                  hint: 'กรุณาระบุวัตถุประสงค์',
                  prefixIcon: Icons.edit_rounded,
                ),
              ],
              
              SizedBox(height: 16.h),

              CustomTextField(
                controller: _notesController,
                label: 'หมายเหตุ',
                hint: 'หมายเหตุเพิ่มเติม (ถ้ามี)',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
              ),

              SizedBox(height: 24.h),

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
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

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

  Widget _buildPurposeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('วัตถุประสงค์', style: AppTextStyles.label),
        SizedBox(height: 8.h),
        
        InkWell(
          onTap: () => _showPurposeBottomSheet(),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _selectedPurpose != null
                    ? _getPurposeIcon(_selectedPurpose!)
                    : Icon(
                        Icons.comment_rounded,
                        color: AppColors.textHint,
                        size: 20.sp,
                      ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    _selectedPurpose ?? 'เลือกวัตถุประสงค์',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _selectedPurpose != null 
                          ? AppColors.textPrimary 
                          : AppColors.textHint,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.primary,
                  size: 28.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPurposeBottomSheet() {
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
            
            Text(
              'เลือกวัตถุประสงค์',
              style: AppTextStyles.h4,
            ),
            SizedBox(height: 20.h),
            
            ..._purposeOptions.map((purpose) => _buildPurposeOption(purpose)).toList(),
            
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeOption(String purpose) {
    final isSelected = _selectedPurpose == purpose;
    
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: _getPurposeIcon(purpose),
      ),
      title: Text(
        purpose,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 24.sp,
            )
          : null,
      onTap: () {
        setState(() {
          _selectedPurpose = purpose;
          if (_selectedPurpose != 'อื่นๆ') {
            _purposeOtherController.clear();
          }
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _getPurposeIcon(String purpose) {
    IconData iconData;
    Color iconColor;

    switch (purpose) {
      case 'นิติบุคคล':
        iconData = Icons.business_rounded;
        iconColor = AppColors.primary;
        break;
      case 'สำนักงานขาย':
        iconData = Icons.store_rounded;
        iconColor = AppColors.accent;
        break;
      case 'พบลูกบ้าน':
        iconData = Icons.people_rounded;
        iconColor = AppColors.success;
        break;
      case 'ผู้รับเหมา':
        iconData = Icons.construction_rounded;
        iconColor = AppColors.warning;
        break;
      case 'ส่งของ':
        iconData = Icons.local_shipping_rounded;
        iconColor = AppColors.info;
        break;
      case 'อื่นๆ':
        iconData = Icons.more_horiz_rounded;
        iconColor = AppColors.textSecondary;
        break;
      default:
        iconData = Icons.help_outline_rounded;
        iconColor = AppColors.textHint;
    }

    return Icon(
      iconData,
      size: 20.sp,
      color: iconColor,
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('รูปถ่าย (สูงสุด 3 รูป)', style: AppTextStyles.label),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'ไม่บังคับ',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.info,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              Expanded(
                child: _buildPhotoSlot(i),
              ),
              if (i < 2) SizedBox(width: 8.w),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(int index) {
    final hasPhoto = _photoFiles[index] != null;
    
    return GestureDetector(
      onTap: () => _showPhotoOptions(index),
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: hasPhoto ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasPhoto ? AppColors.primary : AppColors.border,
            width: hasPhoto ? 2 : 1,
          ),
          image: hasPhoto
              ? DecorationImage(
                  image: FileImage(_photoFiles[index]!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasPhoto
            ? Stack(
                children: [
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _photoFiles[index] = null),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 28.sp,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'รูปที่ ${index + 1}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showPhotoOptions(int index) {
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
            Text('เลือกรูปภาพที่ ${index + 1}', style: AppTextStyles.h4),
            SizedBox(height: 20.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 24.sp),
              ),
              title: Text('ถ่ายรูปด้วยกล้อง', style: AppTextStyles.bodyMedium),
              subtitle: Text('เปิดกล้องเพื่อถ่ายรูป', style: AppTextStyles.caption),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(index);
              },
            ),
            SizedBox(height: 8.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.photo_library_rounded, color: AppColors.accent, size: 24.sp),
              ),
              title: Text('เลือกจากคลัง', style: AppTextStyles.bodyMedium),
              subtitle: Text('เลือกรูปจาก Gallery', style: AppTextStyles.caption),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(index);
              },
            ),
            if (_photoFiles[index] != null) ...[
              SizedBox(height: 8.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.delete_rounded, color: AppColors.error, size: 24.sp),
                ),
                title: Text('ลบรูป', style: AppTextStyles.bodyMedium),
                subtitle: Text('ลบรูปที่เลือก', style: AppTextStyles.caption),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoFiles[index] = null);
                },
              ),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(int index) async {
    final file = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (file != null) {
      setState(() => _photoFiles[index] = file);
    }
  }

  Future<void> _pickFromGallery(int index) async {
    final file = await CameraHelper.pickFromGallery();
    if (file != null) {
      final compressed = await CameraHelper.compressImage(file);
      setState(() => _photoFiles[index] = compressed ?? file);
    }
  }

  Widget _buildVehicleTypeCard(String type, IconData icon) {
    final isSelected = _vehicleType == type;

    return GestureDetector(
      onTap: () => setState(() => _vehicleType = type),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
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