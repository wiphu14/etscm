import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class ExcelHelper {
  /// ส่งออกรายงานการเข้าออกเป็น Excel
  static Future<String?> exportEntryExitReport({
    required List<Map<String, dynamic>> data,
    required String villageName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return null;
      }

      // Create Excel
      var excel = Excel.createExcel();
      Sheet sheet = excel['รายงานเข้า-ออก'];

      // Remove default sheet
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Header Styling
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#2196F3'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      // Title
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('K1'),
      );
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('รายงานการเข้า-ออก: $villageName');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Date Range
      sheet.merge(
        CellIndex.indexByString('A2'),
        CellIndex.indexByString('K2'),
      );
      var dateCell = sheet.cell(CellIndex.indexByString('A2'));
      dateCell.value = TextCellValue(
          'ระหว่างวันที่ ${DateFormat('d/M/yyyy').format(startDate)} - ${DateFormat('d/M/yyyy').format(endDate)}');
      dateCell.cellStyle = CellStyle(
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Column Headers
      final headers = [
        'ลำดับ',
        'วันที่',
        'ชื่อ-นามสกุล',
        'เบอร์โทร',
        'ประเภทยานพาหนะ',
        'ทะเบียนรถ',
        'บ้านเลขที่',
        'ชื่อเจ้าบ้าน',
        'เวลาเข้า',
        'เวลาออก',
        'ระยะเวลา (นาที)',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Data Rows
      CellStyle dataStyle = CellStyle(
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      for (var i = 0; i < data.length; i++) {
        final entry = data[i];
        final rowIndex = i + 4;

        // Calculate duration
        int? durationMinutes;
        if (entry['exit_time'] != null && entry['entry_time'] != null) {
          final duration = (entry['exit_time'] as DateTime)
              .difference(entry['entry_time'] as DateTime);
          durationMinutes = duration.inMinutes;
        }

        final rowData = [
          i + 1,
          DateFormat('d/M/yyyy').format(entry['entry_time']),
          entry['visitor_name'] ?? '',
          entry['phone'] ?? '',
          entry['vehicle_type'] ?? '',
          entry['license_plate'] ?? '',
          entry['house_number'] ?? '',
          entry['resident_name'] ?? '',
          entry['entry_time'] != null
              ? DateFormat('HH:mm').format(entry['entry_time'])
              : '',
          entry['exit_time'] != null
              ? DateFormat('HH:mm').format(entry['exit_time'])
              : 'ยังไม่ออก',
          durationMinutes?.toString() ?? '',
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          final value = rowData[j];
          if (value is int) {
            cell.value = IntCellValue(value);
          } else if (value is double) {
            cell.value = DoubleCellValue(value);
          } else {
            cell.value = TextCellValue(value.toString());
          }
          cell.cellStyle = dataStyle;
        }
      }

      // Summary
      final summaryRow = data.length + 5;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow),
      );
      var summaryCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
      );
      summaryCell.value = TextCellValue('จำนวนรวม:');
      summaryCell.cellStyle = CellStyle(bold: true, fontSize: 12);

      var totalCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow),
      );
      totalCell.value = TextCellValue('${data.length} รายการ');
      totalCell.cellStyle = CellStyle(bold: true, fontSize: 12);

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15.0);
      }

      // Save file
      final directory = await getExternalStorageDirectory();
      final fileName =
          'รายงานเข้าออก_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory!.path}/$fileName';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      return filePath;
    } catch (e) {
      debugPrint('Export Excel error: $e');
      return null;
    }
  }

  /// ส่งออกรายชื่อผู้มาติดต่อทั้งหมด
  static Future<String?> exportVisitorList({
    required List<Map<String, dynamic>> visitors,
    required String villageName,
  }) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) return null;

      var excel = Excel.createExcel();
      Sheet sheet = excel['รายชื่อผู้มาติดต่อ'];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#2196F3'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      // Title
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('F1'),
      );
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('รายชื่อผู้มาติดต่อ: $villageName');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Headers
      final headers = [
        'ลำดับ',
        'ชื่อ-นามสกุล',
        'เบอร์โทร',
        'ประเภทยานพาหนะ',
        'ทะเบียนรถ',
        'จำนวนครั้งที่มา',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Data
      for (var i = 0; i < visitors.length; i++) {
        final visitor = visitors[i];
        final rowData = [
          i + 1,
          visitor['full_name'] ?? '',
          visitor['phone'] ?? '',
          visitor['vehicle_type'] ?? '',
          visitor['license_plate'] ?? '',
          visitor['visit_count'] ?? 1,
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 3),
          );
          final value = rowData[j];
          if (value is int) {
            cell.value = IntCellValue(value);
          } else if (value is double) {
            cell.value = DoubleCellValue(value);
          } else {
            cell.value = TextCellValue(value.toString());
          }
        }
      }

      // Auto-fit
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 18.0);
      }

      // Save
      final directory = await getExternalStorageDirectory();
      final fileName =
          'รายชื่อผู้มาติดต่อ_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory!.path}/$fileName';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      return filePath;
    } catch (e) {
      debugPrint('Export visitor list error: $e');
      return null;
    }
  }

  /// ส่งออกสถิติรายเดือน
  static Future<String?> exportMonthlyStats({
    required Map<String, dynamic> stats,
    required String villageName,
    required DateTime month,
  }) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) return null;

      var excel = Excel.createExcel();
      Sheet sheet = excel['สถิติรายเดือน'];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Title
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('D1'),
      );
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(
          'สถิติรายเดือน: ${DateFormat('MMMM yyyy', 'th').format(month)}');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(villageName);
      sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Stats
      final statsData = [
        ['สถิติ', 'จำนวน'],
        ['จำนวนผู้เข้าทั้งหมด', stats['total_entries'] ?? 0],
        ['จำนวนผู้ออกทั้งหมด', stats['total_exits'] ?? 0],
        ['จำนวนผู้มาติดต่อไม่ซ้ำ', stats['unique_visitors'] ?? 0],
        ['เฉลี่ยต่อวัน', stats['avg_per_day'] ?? 0],
      ];

      for (var i = 0; i < statsData.length; i++) {
        for (var j = 0; j < statsData[i].length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 4),
          );
          final value = statsData[i][j];
          if (value is int) {
            cell.value = IntCellValue(value);
          } else if (value is double) {
            cell.value = DoubleCellValue(value);
          } else {
            cell.value = TextCellValue(value.toString());
          }
          
          if (i == 0) {
            cell.cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#2196F3'),
              fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
            );
          }
        }
      }

      sheet.setColumnWidth(0, 25.0);
      sheet.setColumnWidth(1, 15.0);

      // Save
      final directory = await getExternalStorageDirectory();
      final fileName =
          'สถิติรายเดือน_${DateFormat('yyyyMM').format(month)}.xlsx';
      final filePath = '${directory!.path}/$fileName';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      return filePath;
    } catch (e) {
      debugPrint('Export monthly stats error: $e');
      return null;
    }
  }
}