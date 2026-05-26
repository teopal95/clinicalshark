import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF1B4F72);
  static const secondaryColor = Color(0xFF2E86C1);
  static const accentColor = Color(0xFF17A589);
  static const backgroundColor = Color(0xFFF4F6F9);

  static const Map<String, Color> _statusColors = {
    'RECRUITING': Color(0xFF27AE60),
    'NOT_YET_RECRUITING': Color(0xFFF39C12),
    'ACTIVE_NOT_RECRUITING': Color(0xFF2980B9),
    'COMPLETED': Color(0xFF7F8C8D),
    'TERMINATED': Color(0xFFE74C3C),
    'WITHDRAWN': Color(0xFFE74C3C),
    'SUSPENDED': Color(0xFFE67E22),
    'ENROLLING_BY_INVITATION': Color(0xFF8E44AD),
    'UNKNOWN': Color(0xFF95A5A6),
  };

  static Color getStatusColor(String status) =>
      _statusColors[status] ?? const Color(0xFF95A5A6);

  static String getStatusLabel(String status) => status
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
      .join(' ');

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
