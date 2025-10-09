import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class PrintHelper {
  /// ตรวจสอบว่าเครื่อง Sunmi พร้อมใช้งานหรือไม่
  static Future<bool> checkPrinterStatus() async {
    try {
      // ทดสอบพิมพ์ข้อความว่างเพื่อเช็คสถานะ
      await SunmiPrinter.printText('');
      return true;
    } catch (e) {
      debugPrint('Printer check error: $e');
      return false;
    }
  }

  /// พิมพ์ใบผ่านเข้า
  static Future<bool> printEntryPass({
    required String visitorName,
    required String phone,
    required String licensePlate,
    required String vehicleType,
    required String houseNumber,
    required String residentName,
    required String purpose,
    required DateTime entryTime,
    required String villageName,
    required String staffName,
  }) async {
    try {
      // Header
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.printText('🏘️');
      await SunmiPrinter.printText('ใบผ่านเข้า-ออก');
      await SunmiPrinter.printText(villageName);
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.lineWrap(1);

      // Entry Badge
      await SunmiPrinter.printText('🟢 เข้า');
      await SunmiPrinter.lineWrap(1);

      // Date & Time
      await SunmiPrinter.printText(
        'วันที่: ${DateFormat('d/M/yyyy', 'th').format(entryTime)}',
      );
      await SunmiPrinter.printText(
        'เวลา: ${DateFormat('HH:mm น.').format(entryTime)}',
      );
      await SunmiPrinter.printText('───────────────────────');
      
      // Visitor Information
      await SunmiPrinter.printText('ข้อมูลผู้มาติดต่อ');
      await SunmiPrinter.printText('ชื่อ: $visitorName');
      await SunmiPrinter.printText('เบอร์: $phone');
      await SunmiPrinter.printText('ยานพาหนะ: $vehicleType');
      await SunmiPrinter.printText('ทะเบียน: $licensePlate');
      await SunmiPrinter.printText('───────────────────────');
      
      // Destination
      await SunmiPrinter.printText('จุดหมาย');
      await SunmiPrinter.printText('บ้านเลขที่: $houseNumber');
      await SunmiPrinter.printText('เจ้าบ้าน: $residentName');
      await SunmiPrinter.printText('วัตถุประสงค์: $purpose');
      await SunmiPrinter.printText('───────────────────────');
      
      // Staff Info
      await SunmiPrinter.printText('บันทึกโดย: $staffName');
      await SunmiPrinter.lineWrap(1);
      
      // Footer
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.printText('กรุณาเก็บใบผ่านนี้ไว้');
      await SunmiPrinter.printText('สำหรับแสดงขณะออก');
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.lineWrap(3);
      
      // Cut paper
      await SunmiPrinter.cutPaper();
      
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  /// พิมพ์ใบยืนยันออก
  static Future<bool> printExitReceipt({
    required String visitorName,
    required String licensePlate,
    required String houseNumber,
    required DateTime entryTime,
    required DateTime exitTime,
    required String villageName,
    required String staffName,
  }) async {
    try {
      // Header
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.printText('🏘️');
      await SunmiPrinter.printText('ใบยืนยันออก');
      await SunmiPrinter.printText(villageName);
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.lineWrap(1);

      // Exit Badge
      await SunmiPrinter.printText('🔴 ออก');
      await SunmiPrinter.lineWrap(1);

      // Information
      await SunmiPrinter.printText('───────────────────────');
      await SunmiPrinter.printText('ชื่อ: $visitorName');
      await SunmiPrinter.printText('ทะเบียน: $licensePlate');
      await SunmiPrinter.printText('บ้านเลขที่: $houseNumber');
      await SunmiPrinter.printText('───────────────────────');
      
      // Time Details
      await SunmiPrinter.printText(
        'เข้า: ${DateFormat('HH:mm น.').format(entryTime)}',
      );
      await SunmiPrinter.printText(
        'ออก: ${DateFormat('HH:mm น.').format(exitTime)}',
      );
      
      final duration = exitTime.difference(entryTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      await SunmiPrinter.printText('ระยะเวลา: $hours ชม. $minutes นาที');
      await SunmiPrinter.printText('───────────────────────');
      
      // Staff Info
      await SunmiPrinter.printText('บันทึกโดย: $staffName');
      await SunmiPrinter.lineWrap(1);
      
      // Footer
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.printText('ขอบคุณที่ใช้บริการ');
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.lineWrap(3);
      
      // Cut paper
      await SunmiPrinter.cutPaper();
      
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  /// พิมพ์รายงานสรุปประจำวัน
  static Future<bool> printDailyReport({
    required DateTime date,
    required int totalEntries,
    required int totalExits,
    required int currentVisitors,
    required String villageName,
    required String staffName,
  }) async {
    try {
      // Header
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.printText('รายงานสรุปประจำวัน');
      await SunmiPrinter.printText(villageName);
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.lineWrap(1);

      // Date
      await SunmiPrinter.printText(
        'วันที่: ${DateFormat('d MMMM yyyy', 'th').format(date)}',
      );
      await SunmiPrinter.printText('───────────────────────');
      await SunmiPrinter.lineWrap(1);
      
      // Statistics
      await SunmiPrinter.printText('สถิติ');
      await SunmiPrinter.lineWrap(1);
      
      await SunmiPrinter.printText('🟢 ผู้เข้า: $totalEntries คน');
      await SunmiPrinter.printText('🔴 ผู้ออก: $totalExits คน');
      await SunmiPrinter.printText('👥 อยู่ภายใน: $currentVisitors คน');
      await SunmiPrinter.lineWrap(1);
      
      await SunmiPrinter.printText('───────────────────────');
      
      // Staff Info
      await SunmiPrinter.printText('พิมพ์โดย: $staffName');
      await SunmiPrinter.printText(
        'เวลา: ${DateFormat('HH:mm น.').format(DateTime.now())}',
      );
      await SunmiPrinter.lineWrap(1);
      
      // Footer
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.lineWrap(3);
      
      // Cut paper
      await SunmiPrinter.cutPaper();
      
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  /// ทดสอบเครื่องพิมพ์
  static Future<bool> printTestPage() async {
    try {
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.printText('ทดสอบเครื่องพิมพ์');
      await SunmiPrinter.lineWrap(1);
      
      await SunmiPrinter.printText('Sunmi Printer Test');
      await SunmiPrinter.lineWrap(1);
      
      await SunmiPrinter.printText('───────────────────────');
      await SunmiPrinter.printText('Status: ✓ OK');
      await SunmiPrinter.printText(
        'Time: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      );
      await SunmiPrinter.printText(
        'Date: ${DateFormat('d/M/yyyy').format(DateTime.now())}',
      );
      await SunmiPrinter.printText('───────────────────────');
      await SunmiPrinter.lineWrap(1);
      
      await SunmiPrinter.printText('✓ Printer Ready');
      await SunmiPrinter.printText('═══════════════════════');
      await SunmiPrinter.lineWrap(3);
      
      await SunmiPrinter.cutPaper();
      
      return true;
    } catch (e) {
      debugPrint('Print test error: $e');
      return false;
    }
  }
}