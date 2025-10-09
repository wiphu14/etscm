import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum ButtonType { primary, success, warning, error, outline }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final double? width;

  const CustomButton({
    super.key, // แก้ไข error ที่ 1
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height,
    this.width,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case ButtonType.primary:
        return AppColors.primary;
      case ButtonType.success:
        return AppColors.success;
      case ButtonType.warning:
        return AppColors.warning;
      case ButtonType.error:
        return AppColors.error;
      case ButtonType.outline:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (type == ButtonType.outline) {
      return AppColors.primary;
    }
    return AppColors.textWhite;
  }

  BoxDecoration _getDecoration() {
    if (type == ButtonType.outline) {
      return BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary, width: 2),
      );
    }
    
    return BoxDecoration(
      gradient: type == ButtonType.primary 
        ? AppColors.primaryGradient 
        : null,
      color: type != ButtonType.primary ? _getBackgroundColor() : null,
      borderRadius: BorderRadius.circular(12.r),
      boxShadow: [
        BoxShadow(
          color: _getBackgroundColor().withValues(alpha: 0.3), // แก้ไข error ที่ 2
          blurRadius: 8,
          offset: const Offset(0, 4), // เพิ่ม const
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 54.h,
      width: isFullWidth ? double.infinity : width,
      decoration: _getDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      height: 24.h,
                      width: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTextColor(),
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: _getTextColor(),
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        text,
                        style: AppTextStyles.button.copyWith(
                          color: _getTextColor(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ปุ่มแบบไอคอนกลม
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;

  const CustomIconButton({
    super.key, // แก้ไข error ที่ 3
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size ?? 48.h,
      width: size ?? 48.w,
      decoration: BoxDecoration(
        gradient: backgroundColor == null ? AppColors.primaryGradient : null,
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4), // เพิ่ม const
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(100),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.textWhite,
            size: 24.sp,
          ),
        ),
      ),
    );
  }
}