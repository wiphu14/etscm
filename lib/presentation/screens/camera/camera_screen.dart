import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/camera_helper.dart';
import '../../widgets/custom_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isLoading = true;
  bool _isTakingPicture = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // ขอ permission
      final hasPermission = await CameraHelper.requestCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('กรุณาอนุญาตการใช้งานกล้อง'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // รับรายชื่อกล้อง
      _cameras = await CameraHelper.getAvailableCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่พบกล้องในอุปกรณ์'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // เริ่มต้นกล้อง
      await _setupCamera(_selectedCameraIndex);
    } catch (e) {
      print('Init camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    final camera = _cameras[cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Setup camera error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile photo = await _controller!.takePicture();
      final File imageFile = File(photo.path);

      // บีบอัดรูป
      final compressedFile = await CameraHelper.compressImage(imageFile);

      if (mounted) {
        Navigator.pop(context, compressedFile ?? imageFile);
      }
    } catch (e) {
      print('Take picture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ถ่ายรูปไม่สำเร็จ'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isLoading = true;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    await _setupCamera(_selectedCameraIndex);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_controller != null && _controller!.value.isInitialized)
              SizedBox.expand(
                child: CameraPreview(_controller!),
              )
            else
              Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

            // Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),

            // Grid Overlay (สำหรับจัดองค์ประกอบ)
            if (_controller != null && _controller!.value.isInitialized)
              _buildGridOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          Expanded(
            child: Text(
              'ถ่ายรูปผู้มาติดต่อ',
              style: AppTextStyles.h4.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          // Switch Camera Button
          if (_cameras.length > 1)
            IconButton(
              onPressed: _switchCamera,
              icon: Icon(
                Icons.flip_camera_ios_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            )
          else
            SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery Button
          GestureDetector(
            onTap: () async {
              final file = await CameraHelper.pickFromGallery();
              if (file != null && mounted) {
                Navigator.pop(context, file);
              }
            },
            child: Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.photo_library_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
          ),

          // Capture Button
          GestureDetector(
            onTap: _isTakingPicture ? null : _takePicture,
            child: Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: _isTakingPicture ? Colors.grey : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Placeholder
          SizedBox(width: 60.w),
        ],
      ),
    );
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: GridPainter(),
      ),
    );
  }
}

// Grid Painter สำหรับ Rule of Thirds
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}