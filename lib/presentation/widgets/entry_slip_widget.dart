import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class EntrySlipWidget extends StatelessWidget {
  final Map<String, dynamic> entryData;
  final VoidCallback? onPrint;
  final VoidCallback? onClose;

  const EntrySlipWidget({
    Key? key,
    required this.entryData,
    this.onPrint,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrCode = entryData['qr_code'] ?? entryData['log_id']?.toString() ?? 'N/A';
    final fullName = entryData['full_name'] ?? '-';
    final idCard = entryData['id_card'] ?? '-';
    final houseNumber = entryData['house_number'] ?? '-';
    final purpose = entryData['purpose'] ?? '-';
    final entryTime = entryData['entry_time'] ?? '-';
    final vehicleType = entryData['vehicle_type'] ?? '-';
    final licensePlate = entryData['license_plate'] ?? '-';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                Text(
                  'บัตรผ่านเข้า',
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ENTRY PASS',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // ============================================
          // QR Code - ขนาดใหญ่ขึ้น
          // ============================================
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: QrImageView(
              data: qrCode,
              version: QrVersions.auto,
              size: 180.w,  // ⬆️ เพิ่มขนาดจาก 120 เป็น 180
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              padding: EdgeInsets.all(8.w),
            ),
          ),

          SizedBox(height: 8.h),

          // QR Code Number
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              qrCode,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16.sp,  // ⬆️ เพิ่มขนาดตัวอักษร
                letterSpacing: 1.5,
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Divider
          Divider(color: AppColors.border, thickness: 1),

          SizedBox(height: 12.h),

          // Entry Info
          _buildInfoRow('ชื่อ-นามสกุล', fullName),
          _buildInfoRow('เลขบัตร ปชช.', _maskIdCard(idCard)),
          _buildInfoRow('บ้านเลขที่', houseNumber),
          _buildInfoRow('วัตถุประสงค์', purpose),
          _buildInfoRow('ยานพาหนะ', vehicleType),
          _buildInfoRow('ทะเบียนรถ', licensePlate),
          
          SizedBox(height: 8.h),
          
          Divider(color: AppColors.border, thickness: 1),
          
          SizedBox(height: 8.h),

          // Entry Time
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                Text(
                  'เวลาเข้า',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  entryTime,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Buttons
          Row(
            children: [
              if (onClose != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(color: AppColors.textSecondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'ปิด',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              if (onClose != null && onPrint != null) SizedBox(width: 12.w),
              if (onPrint != null)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onPrint,
                    icon: Icon(Icons.print_rounded, size: 20.sp),
                    label: Text('พิมพ์บัตร'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            ': ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
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

  String _maskIdCard(String idCard) {
    if (idCard.length >= 13) {
      return '${idCard.substring(0, 1)}-xxxx-xxxxx-${idCard.substring(10, 12)}-${idCard.substring(12)}';
    }
    return idCard;
  }
}