import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraHelper {
  static final ImagePicker _picker = ImagePicker();

  /// ขอ Permission กล้อง
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// ถ่ายรูปด้วยกล้อง
  static Future<File?> takePhoto() async {
    try {
      // ขอ permission ก่อน
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        print('Camera permission denied');
        return null;
      }

      // ถ่ายรูป
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Take photo error: $e');
      return null;
    }
  }

  /// เลือกรูปจาก Gallery
  static Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Pick from gallery error: $e');
      return null;
    }
  }

  /// บีบอัดรูปภาพ
  static Future<File?> compressImage(File file, {int quality = 85}) async {
    try {
      // อ่านรูปภาพ
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      // Resize ถ้ารูปใหญ่เกิน
      img.Image resized = image;
      if (image.width > 1024 || image.height > 1024) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1024 : null,
          height: image.height >= image.width ? 1024 : null,
        );
      }

      // บีบอัด
      final compressed = img.encodeJpg(resized, quality: quality);

      // บันทึกไฟล์ใหม่
      final tempDir = await getTemporaryDirectory();
      final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = File('${tempDir.path}/$fileName');
      await compressedFile.writeAsBytes(compressed);

      return compressedFile;
    } catch (e) {
      print('Compress image error: $e');
      return null;
    }
  }

  /// บันทึกรูปถาวร
  static Future<File?> saveImagePermanently(
    File tempFile,
    String visitorCode,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final visitorDir = Directory('${directory.path}/visitor_photos');

      // สร้างโฟลเดอร์ถ้ายังไม่มี
      if (!await visitorDir.exists()) {
        await visitorDir.create(recursive: true);
      }

      // ชื่อไฟล์
      final fileName = '${visitorCode}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${visitorDir.path}/$fileName');

      // คัดลอกไฟล์
      await tempFile.copy(savedFile.path);

      return savedFile;
    } catch (e) {
      print('Save image permanently error: $e');
      return null;
    }
  }

  /// ลบรูปภาพ
  static Future<bool> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Delete image error: $e');
      return false;
    }
  }

  /// รับรายชื่อกล้องที่มี
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      print('Get available cameras error: $e');
      return [];
    }
  }

  /// แปลง File เป็น Base64 (สำหรับส่ง API)
  static Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return bytes.toString();
    } catch (e) {
      print('File to base64 error: $e');
      return null;
    }
  }

  /// คำนวณขนาดไฟล์ (MB)
  static Future<double> getFileSize(File file) async {
    try {
      final bytes = await file.length();
      return bytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      print('Get file size error: $e');
      return 0;
    }
  }
}