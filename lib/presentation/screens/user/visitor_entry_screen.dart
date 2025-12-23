import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/entry_log_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_card.dart';
import '../../providers/auth_provider.dart';

class VisitorEntryScreen extends StatefulWidget {
  const VisitorEntryScreen({super.key});

  @override
  State<VisitorEntryScreen> createState() => _VisitorEntryScreenState();
}

class _VisitorEntryScreenState extends State<VisitorEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _residentNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  String _selectedVehicleType = 'รถยนต์';
  String _selectedPurpose = 'พบลูกบ้าน';
  bool _isLoading = false;
  bool _printPass = true; // ค่าเริ่มต้นพิมพ์ใบผ่าน
  
  // Photos (3 รูป)
  final List<File?> _photoFiles = [null, null, null];
  
  // Vehicle types
  final List<String> _vehicleTypes = [
    'รถยนต์',
    'รถจักรยานยนต์',
    'รถตู้',
    'รถบรรทุก',
    'เดินเท้า',
  ];
  
  // Purposes
  final List<String> _purposes = [
    'นิติบุคคล',
    'สำนักงานขาย',
    'พบลูกบ้าน',
    'ผู้รับเหมา',
    'ส่งของ',
    'อื่นๆ',
  ];
  
  // API Service & Repository
  late ApiService _apiService;
  late EntryLogRepository _entryLogRepository;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _entryLogRepository = EntryLogRepository(_apiService);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _licensePlateController.dispose();
    _houseNumberController.dispose();
    _residentNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index, {bool fromCamera = true}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _photoFiles[index] = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('🔴 Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปได้: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _photoFiles[index] = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('🔵 ========================================');
      debugPrint('🔵 เริ่มบันทึกข้อมูลผู้มาติดต่อ...');
      debugPrint('🔵 ========================================');
      
      // Visitor Data
      final visitorData = {
        'full_name': _fullNameController.text.trim(),
        'id_card': _idCardController.text.trim(),
        'phone': _phoneController.text.trim(),
        'vehicle_type': _selectedVehicleType,
        'license_plate': _licensePlateController.text.trim().toUpperCase(),
        'village_id': authProvider.villageId ?? 1,
      };
      
      // Entry Data
      final entryData = {
        'house_number': _houseNumberController.text.trim(),
        'resident_name': _residentNameController.text.trim(),
        'purpose': _selectedPurpose,
        'entry_notes': _notesController.text.trim(),
        'entry_by': authProvider.userId ?? 0,
        'village_id': authProvider.villageId ?? 1,
      };
      
      debugPrint('🔵 Visitor Data: $visitorData');
      debugPrint('🔵 Entry Data: $entryData');
      
      // Get first available photo
      File? firstPhoto;
      for (var photo in _photoFiles) {
        if (photo != null) {
          firstPhoto = photo;
          break;
        }
      }
      
      // Call API
      final result = await _entryLogRepository.createEntrySunmi(
        visitorData: visitorData,
        entryData: entryData,
        photoFile: firstPhoto,
      );
      
      debugPrint('🟡 API Result: $result');
      
      if (result['success'] == true) {
        debugPrint('🟢 บันทึกสำเร็จ!');
        
        // ดึงข้อมูลสำหรับ QR Code
        final data = result['data'] ?? {};
        final qrCode = data['qr_code'] ?? data['visitor_code'] ?? 'VIS-${DateTime.now().millisecondsSinceEpoch}';
        
        if (mounted) {
          // แสดง dialog พิมพ์ใบผ่าน
          if (_printPass) {
            await _showPrintPassDialog(
              qrCode: qrCode.toString(),
              visitorName: _fullNameController.text.trim(),
              licensePlate: _licensePlateController.text.trim().toUpperCase(),
              houseNumber: _houseNumberController.text.trim(),
              purpose: _selectedPurpose,
            );
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'บันทึกข้อมูลสำเร็จ'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          Navigator.pop(context, true);
        }
      } else {
        debugPrint('🔴 บันทึกไม่สำเร็จ: ${result['message']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'บันทึกข้อมูลไม่สำเร็จ'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🔴 Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// แสดง Dialog พิมพ์ใบผ่าน
  Future<void> _showPrintPassDialog({
    required String qrCode,
    required String visitorName,
    required String licensePlate,
    required String houseNumber,
    required String purpose,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year + 543}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 300.w,
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ใบผ่านเข้า', style: AppTextStyles.h4),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // Pass Card Preview
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    // Village Name
                    Text(
                      'บัตรผู้มาติดต่อ',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    // QR Code
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: QrImageView(
                        data: qrCode,
                        version: QrVersions.auto,
                        size: 120.w,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    // QR Code Text
                    Text(
                      qrCode,
                      style: AppTextStyles.caption.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    Divider(color: AppColors.divider),
                    
                    SizedBox(height: 8.h),
                    
                    // Info
                    _buildPassInfoRow('ชื่อ', visitorName),
                    _buildPassInfoRow('ทะเบียน', licensePlate),
                    _buildPassInfoRow('บ้านเลขที่', houseNumber),
                    _buildPassInfoRow('วัตถุประสงค์', purpose),
                    _buildPassInfoRow('วันที่', dateStr),
                    _buildPassInfoRow('เวลาเข้า', '$timeStr น.'),
                  ],
                ),
              ),
              
              SizedBox(height: 20.h),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text('ปิด', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _printPassCard(qrCode, visitorName, licensePlate, houseNumber, purpose);
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.print_rounded, size: 20.sp),
                      label: Text('พิมพ์'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// พิมพ์บัตรผ่าน (สำหรับ Sunmi Printer)
  void _printPassCard(String qrCode, String name, String plate, String house, String purpose) {
    // TODO: Implement Sunmi Printer
    debugPrint('🖨️ พิมพ์ใบผ่าน: $qrCode');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กำลังพิมพ์ใบผ่าน...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('บันทึกผู้เข้า', style: AppTextStyles.h4.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visitor Info Section
                    _buildVisitorInfoSection(),
                    
                    SizedBox(height: 20.h),
                    
                    // Vehicle Info Section
                    _buildVehicleInfoSection(),
                    
                    SizedBox(height: 20.h),
                    
                    // Destination Section
                    _buildDestinationSection(),
                    
                    SizedBox(height: 20.h),
                    
                    // Purpose Section
                    _buildPurposeSection(),
                    
                    SizedBox(height: 20.h),
                    
                    // Notes Section
                    _buildNotesSection(),
                    
                    SizedBox(height: 20.h),
                    
                    // Photos Section
                    _buildPhotosSection(),
                    
                    SizedBox(height: 20.h),
                    
                    // Print Pass Option
                    _buildPrintPassOption(),
                    
                    SizedBox(height: 100.h), // Space for bottom button
                  ],
                ),
              ),
            ),
            
            // Bottom Button
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: 'บันทึกผู้เข้า',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  icon: Icons.save_rounded,
                  type: ButtonType.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorInfoSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ข้อมูลผู้มาติดต่อ', Icons.person_rounded),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: _fullNameController,
              label: 'ชื่อ-นามสกุล',
              hint: 'กรอกชื่อ-นามสกุล',
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกชื่อ-นามสกุล';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            CustomTextField(
              controller: _idCardController,
              label: 'เลขบัตรประชาชน',
              hint: 'กรอกเลขบัตรประชาชน 13 หลัก (ไม่บังคับ)',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12.h),
            CustomTextField(
              controller: _phoneController,
              label: 'เบอร์โทรศัพท์',
              hint: 'กรอกเบอร์โทรศัพท์ (ไม่บังคับ)',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ข้อมูลยานพาหนะ', Icons.directions_car_rounded),
            SizedBox(height: 16.h),
            
            // Vehicle Type Chips
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _vehicleTypes.map((type) {
                final isSelected = _selectedVehicleType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedVehicleType = type),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      type,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: _licensePlateController,
              label: 'ทะเบียนรถ',
              hint: 'กรอกทะเบียนรถ เช่น กข-1234',
              prefixIcon: Icons.directions_car_outlined,
              validator: (value) {
                if (_selectedVehicleType != 'เดินเท้า' && (value == null || value.isEmpty)) {
                  return 'กรุณากรอกทะเบียนรถ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('จุดหมายปลายทาง', Icons.home_rounded),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: _houseNumberController,
              label: 'บ้านเลขที่',
              hint: 'กรอกบ้านเลขที่ที่ต้องการไป',
              prefixIcon: Icons.home_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกบ้านเลขที่';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            CustomTextField(
              controller: _residentNameController,
              label: 'ชื่อผู้อยู่อาศัย',
              hint: 'กรอกชื่อผู้อยู่อาศัยที่ต้องการพบ (ไม่บังคับ)',
              prefixIcon: Icons.person_pin_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('วัตถุประสงค์', style: AppTextStyles.label),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _purposes.map((purpose) {
            final isSelected = _selectedPurpose == purpose;
            return GestureDetector(
              onTap: () => setState(() => _selectedPurpose = purpose),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  purpose,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('หมายเหตุ', style: AppTextStyles.label),
        SizedBox(height: 8.h),
        CustomCard(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'หมายเหตุเพิ่มเติม (ไม่บังคับ)',
                hintStyle: AppTextStyles.hint,
                prefixIcon: Icon(Icons.note_outlined, color: AppColors.textHint),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Text('รูปภาพ (ไม่บังคับ)', style: AppTextStyles.label),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12.w : 0),
                child: _buildPhotoBox(index),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPhotoBox(int index) {
    final photo = _photoFiles[index];
    
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: photo != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11.r),
                      child: Image.file(
                        photo,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4.w,
                      right: 4.w,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16.sp,
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
                      Icons.add_a_photo_outlined,
                      color: AppColors.textHint,
                      size: 28.sp,
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
      ),
    );
  }

  Widget _buildPrintPassOption() {
    return CustomCard(
      child: InkWell(
        onTap: () => setState(() => _printPass = !_printPass),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.print_rounded,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'พิมพ์ใบผ่าน',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'พิมพ์ใบผ่านให้ผู้มาติดต่อ',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: _printPass,
                onChanged: (value) => setState(() => _printPass = value ?? true),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 8.w),
        Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}