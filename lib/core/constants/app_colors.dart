import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - สีฟ้าสวยๆ ทันสมัย
  static const Color primary = Color(0xFF2196F3); // Blue 500
  static const Color primaryLight = Color(0xFF64B5F6); // Blue 300
  static const Color primaryDark = Color(0xFF1976D2); // Blue 700
  static const Color primaryGradientStart = Color(0xFF42A5F5);
  static const Color primaryGradientEnd = Color(0xFF1E88E5);
  
  // Accent Colors
  static const Color accent = Color(0xFF00BCD4); // Cyan
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color accentDark = Color(0xFF0097A7);
  
  // Background Colors
  static const Color background = Color(0xFFF5F9FC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFE3F2FD);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue
  
  // Entry/Exit Colors
  static const Color entry = Color(0xFF4CAF50); // เข้า - เขียว
  static const Color exit = Color(0xFFFF5722); // ออก - แดง
  
  // Role Colors
  static const Color admin = Color(0xFF9C27B0); // Purple
  static const Color user = Color(0xFF2196F3); // Blue
  
  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  
  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
  
  // Gradients
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );
  
  static LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
  );
  
  static LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
  );
  
  // Glass Effect Colors
static Color glass = Colors.white.withValues(alpha: 0.1);
static Color glassBorder = Colors.white.withValues(alpha: 0.2);
}