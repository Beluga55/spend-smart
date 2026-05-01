import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF000000);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFF000000);
  static const Color successColor = Color(0xFF333333);
  static const Color warningColor = Color(0xFF555555);

  static const Color darkBackgroundColor = Color(0xFF1A1A1A);
  static const Color darkSurfaceColor = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkDividerColor = Color(0xFF404040);
  static const Color darkSuccessColor = Color(0xFFCCCCCC);
  static const Color darkWarningColor = Color(0xFF999999);

  static TextTheme get _soraTextTheme {
    return GoogleFonts.soraTextTheme();
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: _soraTextTheme.copyWith(
        displayLarge: _soraTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
        displayMedium: _soraTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        displaySmall: _soraTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        headlineLarge: _soraTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
        headlineMedium: _soraTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        headlineSmall: _soraTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        titleLarge: _soraTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: _soraTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        titleSmall: _soraTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.sora(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.w500, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.sora(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.sora(color: textSecondary),
        hintStyle: GoogleFonts.sora(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.sora(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        surface: darkSurfaceColor,
        onSurface: darkTextPrimary,
        error: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      textTheme: _soraTextTheme.copyWith(
        displayLarge: _soraTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: darkTextPrimary),
        displayMedium: _soraTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: darkTextPrimary),
        displaySmall: _soraTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: darkTextPrimary),
        headlineLarge: _soraTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600, color: darkTextPrimary),
        headlineMedium: _soraTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: darkTextPrimary),
        headlineSmall: _soraTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: _soraTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleMedium: _soraTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500, color: darkTextPrimary),
        titleSmall: _soraTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: darkTextPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.sora(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkDividerColor),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.w500, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.sora(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.sora(color: darkTextSecondary),
        hintStyle: GoogleFonts.sora(color: darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.sora(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
