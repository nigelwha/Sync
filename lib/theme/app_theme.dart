import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Цвета
  static const Color background = Color(0xFFF5F7FA);
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE5E7EB);

  // Типографика
  static TextStyle headline1 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static TextStyle headline2 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static TextStyle bodyText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  static TextStyle label = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Тема для MaterialApp
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      error: error,
    ),
    textTheme: TextTheme(
      displayLarge: headline1,
      displayMedium: headline2,
      bodyLarge: bodyText,
      bodyMedium: label,
      labelLarge: buttonText,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: buttonText,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: label,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(color: divider),
  );
}