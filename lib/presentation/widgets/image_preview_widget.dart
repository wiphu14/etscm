import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ImagePreviewWidget extends StatelessWidget {
  final File imageFile;
  final VoidCallback? onClose;
  final VoidCallback? onRetake;
  final VoidCallback? onConfirm;

  const ImagePreviewWidget({
    super.key, // แก้ไข error ที่ 1
    required this.imageFile,
    this.onClose,
    this.onRetake,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6), // แก้ไข error ที่ 2
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: onClose ?? () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    Text(
                      'ตรวจสอบรูปภาพ',
                      style: AppTextStyles.h4.copyWith(color: Colors.white),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            if (onRetake != null || onConfirm != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8), // แก้ไข error ที่ 3
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      if (onRetake != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onRetake,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              'ถ่ายใหม่',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              side: const BorderSide(color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      if (onRetake != null && onConfirm != null)
                        SizedBox(width: 12.w),
                      if (onConfirm != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onConfirm,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                              'ใช้รูปนี้',
                              style: AppTextStyles.button,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Full Screen Image Viewer
class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final bool isNetworkImage;

  const FullScreenImageViewer({
    super.key, // แก้ไข error ที่ 4
    required this.imagePath,
    this.isNetworkImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: isNetworkImage
              ? Image.network(imagePath, fit: BoxFit.contain)
              : Image.file(File(imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}