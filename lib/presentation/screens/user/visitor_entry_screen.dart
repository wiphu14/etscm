import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/print_helper.dart';
import '../../../core/utils/camera_helper.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/entry_log_repository.dart';
import '../../../data/repositories/visitor_repository.dart';
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

  // API Service & Repository
  late ApiService _apiService;
  late EntryLogRepository _entryLogRepository;
  late VisitorRepository _visitorRepository;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _entryLogRepository = EntryLogRepository(_apiService);
    _visitorRepository = VisitorRepository(_apiService);
  }

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

      debugPrint('🔵 ========================================');
      debugPrint('🔵 เริ่มบันทึกผู้เข้า...');
      debugPrint('🔵 Village ID: ${authProvider.villageId}');
      debugPrint('🔵 User ID: ${authProvider.userId}');
      debugPrint('🔵 ========================================');

      // เตรียมข้อมูลผู้มาติดต่อ
      final visitorData = {
        'village_id': authProvider.villageId,
        'full_name': _nameController.text.isEmpty ? null : _nameController.text.trim(),
        'id_card': _idCardController.text.isEmpty ? null : _idCardController.text.trim(),
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
        'vehicle_type': _vehicleType,
        'license_plate': _licensePlateController.text.isEmpty ? null : _licensePlateController.text.trim(),
      };

      // เตรียมข้อมูล Entry
      final entryData = {
        'village_id': authProvider.villageId,
        'house_number': _houseNumberController.text.isEmpty ? 'ไม่ระบุ' : _houseNumberController.text.trim(),
        'resident_name': _residentNameController.text.isEmpty ? null : _residentNameController.text.trim(),
        'purpose': finalPurpose,
        'purpose_detail': _notesController.text.isEmpty ? null : _notesController.text.trim(),
        'entry_by': authProvider.userId,
        'entry_notes': _notesController.text.isEmpty ? null : _notesController.text.trim(),
      };

      debugPrint('🔵 Visitor Data: $visitorData');
      debugPrint('🔵 Entry Data: $entryData');

      // เรียก API บันทึกผู้เข้า
      final result = await _entryLogRepository.createEntrySunmi(
        visitorData: visitorData,
        entryData: entryData,
      );

      debugPrint('🟡 API Response: $result');

      if (result['success'] == true) {
        _generatedQRCode = result['qr_code'] ?? result['data']?['qr_code'] ?? 'QR-${DateTime.now().millisecondsSinceEpoch}';
        
        debugPrint('🟢 บันทึกสำเร็จ! QR Code: $_generatedQRCode');

        // Upload รูปภาพ (ถ้ามี)
        for (int i = 0; i < _photoFiles.length; i++) {
          if (_photoFiles[i] != null) {
            try {
              await _visitorRepository.uploadPhoto(
                photoFile: _photoFiles[i]!,
                visitorCode: _generatedQRCode!,
                photoIndex: i + 1,
              );
              debugPrint('🟢 Upload รูปที่ ${i + 1} สำเร็จ');
            } catch (e) {
              debugPrint('🔴 Upload รูปที่ ${i + 1} ไม่สำเร็จ: $e');
            }
          }
        }
        
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
            qrCode: _generatedQRCode!,
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
      } else {
        // บันทึกไม่สำเร็จ
        debugPrint('🔴 บันทึกไม่สำเร็จ: ${result['message']}');
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
                          size: 180.w, // ขยายขนาด QR Code
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
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        if (_printReceipt)
                          Row(
                            children: [
                              Icon(Icons.print_rounded, size: 16.sp, color: AppColors.success),
                              SizedBox(width: 6.w),
                              Text('พิมพ์ใบผ่านแล้ว', style: AppTextStyles.caption),
                            ],
                          ),
                        if (photoCount > 0) ...[
                          if (_printReceipt) SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(Icons.photo_camera_rounded, size: 16.sp, color: AppColors.info),
                              SizedBox(width: 6.w),
                              Text('บันทึกรูปภาพ $photoCount รูป', style: AppTextStyles.caption),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 16.h),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text('กลับหน้าหลัก', style: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                        )),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetForm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.entry,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text('บันทึกคนต่อไป', style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: 13.sp,
                        )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _idCardController.clear();
    _phoneController.clear();
    _licensePlateController.clear();
    _houseNumberController.clear();
    _residentNameController.clear();
    _purposeOtherController.clear();
    _notesController.clear();
    setState(() {
      _vehicleType = 'รถยนต์';
      _selectedPurpose = null;
      _photoFiles[0] = null;
      _photoFiles[1] = null;
      _photoFiles[2] = null;
      _generatedQRCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('บันทึกผู้เข้า', style: AppTextStyles.h4.copyWith(color: Colors.white)),
        backgroundColor: AppColors.entry,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ข้อมูลผู้มาติดต่อ
              _buildSectionTitle('ข้อมูลผู้มาติดต่อ', Icons.person_rounded),
              SizedBox(height: 12.h),
              
              CustomTextField(
                controller: _nameController,
                label: 'ชื่อ-นามสกุล',
                hint: 'กรอกชื่อผู้มาติดต่อ (ไม่บังคับ)',
                prefixIcon: Icons.person_outline_rounded,
              ),
              SizedBox(height: 12.h),
              
              CustomTextField(
                controller: _idCardController,
                label: 'เลขบัตรประชาชน',
                hint: 'กรอกเลขบัตรประชาชน (ไม่บังคับ)',
                prefixIcon: Icons.credit_card_rounded,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),
              
              CustomTextField(
                controller: _phoneController,
                label: 'เบอร์โทรศัพท์',
                hint: 'กรอกเบอร์โทรศัพท์ (ไม่บังคับ)',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              
              SizedBox(height: 20.h),
              
              // ข้อมูลยานพาหนะ
              _buildSectionTitle('ข้อมูลยานพาหนะ', Icons.directions_car_rounded),
              SizedBox(height: 12.h),
              
              Text('ประเภทยานพาหนะ', style: AppTextStyles.label),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(child: _buildVehicleTypeCard('รถยนต์', Icons.directions_car_rounded)),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildVehicleTypeCard('รถจักรยานยนต์', Icons.two_wheeler_rounded)),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildVehicleTypeCard('เดินเท้า', Icons.directions_walk_rounded)),
                ],
              ),
              SizedBox(height: 12.h),
              
              CustomTextField(
                controller: _licensePlateController,
                label: 'ทะเบียนรถ',
                hint: 'กรอกทะเบียนรถ (ไม่บังคับ)',
                prefixIcon: Icons.confirmation_number_rounded,
              ),
              
              SizedBox(height: 20.h),
              
              // ข้อมูลการติดต่อ
              _buildSectionTitle('ข้อมูลการติดต่อ', Icons.home_rounded),
              SizedBox(height: 12.h),
              
              CustomTextField(
                controller: _houseNumberController,
                label: 'บ้านเลขที่',
                hint: 'กรอกบ้านเลขที่ที่ไปติดต่อ',
                prefixIcon: Icons.home_outlined,
              ),
              SizedBox(height: 12.h),
              
              CustomTextField(
                controller: _residentNameController,
                label: 'ชื่อผู้พักอาศัย',
                hint: 'กรอกชื่อเจ้าของบ้าน (ไม่บังคับ)',
                prefixIcon: Icons.person_pin_rounded,
              ),
              SizedBox(height: 12.h),
              
              Text('วัตถุประสงค์', style: AppTextStyles.label),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _purposeOptions.map((purpose) {
                  final isSelected = _selectedPurpose == purpose;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPurpose = purpose),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        purpose,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              if (_selectedPurpose == 'อื่นๆ') ...[
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: _purposeOtherController,
                  label: 'ระบุวัตถุประสงค์',
                  hint: 'กรอกวัตถุประสงค์',
                  prefixIcon: Icons.edit_rounded,
                ),
              ],
              
              SizedBox(height: 12.h),
              
              CustomTextField(
                controller: _notesController,
                label: 'หมายเหตุ',
                hint: 'หมายเหตุเพิ่มเติม (ไม่บังคับ)',
                prefixIcon: Icons.note_rounded,
                maxLines: 2,
              ),
              
              SizedBox(height: 20.h),
              
              // รูปภาพ
              _buildSectionTitle('รูปภาพ (ไม่บังคับ)', Icons.photo_camera_rounded),
              SizedBox(height: 12.h),
              
              Row(
                children: [
                  Expanded(child: _buildPhotoSlot(0)),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildPhotoSlot(1)),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildPhotoSlot(2)),
                ],
              ),
              
              SizedBox(height: 20.h),
              
              // ตัวเลือกพิมพ์
              CustomCard(
                child: CheckboxListTile(
                  value: _printReceipt,
                  onChanged: (value) => setState(() => _printReceipt = value ?? true),
                  title: Text('พิมพ์ใบผ่าน', style: AppTextStyles.bodyMedium),
                  subtitle: Text('พิมพ์ใบผ่านให้ผู้มาติดต่อ', style: AppTextStyles.caption),
                  secondary: Icon(Icons.print_rounded, color: AppColors.primary),
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // ปุ่มบันทึก
              CustomButton(
                text: 'บันทึกผู้เข้า',
                onPressed: _handleSave,
                isFullWidth: true,
                isLoading: _isLoading,
                icon: Icons.save_rounded,
                type: ButtonType.primary,
              ),
              
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Text(title, style: AppTextStyles.h4),
      ],
    );
  }

  Widget _buildVehicleTypeCard(String type, IconData icon) {
    final isSelected = _vehicleType == type;

    return GestureDetector(
      onTap: () => setState(() => _vehicleType = type),
      child: Container(
        padding: EdgeInsets.all(12.w),
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
              size: 28.sp,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(height: 6.h),
            Text(
              type,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlot(int index) {
    final hasPhoto = _photoFiles[index] != null;
    
    return GestureDetector(
      onTap: () => _showPhotoOptions(index),
      child: Container(
        height: 100.h,
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
                          size: 14.sp,
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
                    size: 24.sp,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'รูป ${index + 1}',
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
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(index);
              },
            ),
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
}
