import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Default palette ─────────────────────────────────────────────────────────
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

  // ── Calico cat palette ──────────────────────────────────────────────────────
  static const Color catPrimary = Color(0xFFF08080);
  static const Color catBackground = Color(0xFFFFF5EE);
  static const Color catSurface = Color(0xFFFFFFFF);
  static const Color catTextPrimary = Color(0xFF3D2B1F);
  static const Color catTextSecondary = Color(0xFF8B6A55);
  static const Color catDivider = Color(0xFFE8D5C4);

  static const Color catDarkPrimary = Color(0xFFF08080);
  static const Color catDarkBackground = Color(0xFF1C1719);
  static const Color catDarkSurface = Color(0xFF2B2426);
  static const Color catDarkTextPrimary = Color(0xFFF2EEEF);
  static const Color catDarkTextSecondary = Color(0xFFA09498);
  static const Color catDarkDivider = Color(0xFF3B3235);

  // ── Text themes ─────────────────────────────────────────────────────────────
  static TextTheme get _soraTextTheme => GoogleFonts.soraTextTheme();
  static TextTheme get _nunitoTextTheme => GoogleFonts.fredokaTextTheme();

  // ── Default light ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
        outline: dividerColor,
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
        titleTextStyle: GoogleFonts.sora(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor, textStyle: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Default dark ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        surface: darkSurfaceColor,
        onSurface: darkTextPrimary,
        outline: darkDividerColor,
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
        titleTextStyle: GoogleFonts.sora(color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkDividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkDividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 2)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white, textStyle: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Cat light 🐱 ─────────────────────────────────────────────────────────────
  static ThemeData get catLightTheme {
    final t = _nunitoTextTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: catPrimary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFF4978E),
        onPrimaryContainer: catTextPrimary,
        secondary: catTextSecondary,
        onSecondary: Colors.white,
        secondaryContainer: catDivider,
        onSecondaryContainer: catTextPrimary,
        tertiary: catTextSecondary,
        onTertiary: Colors.white,
        surface: catSurface,
        onSurface: catTextPrimary,
        surfaceContainerHighest: catBackground,
        outline: catDivider,
        error: Color(0xFFB00020),
      ),
      scaffoldBackgroundColor: catBackground,
      textTheme: t.copyWith(
        displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: catTextPrimary),
        displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: catTextPrimary),
        displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: catTextPrimary),
        headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: catTextPrimary),
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: catTextPrimary),
        headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: catTextPrimary),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: catTextPrimary),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: catTextPrimary),
        titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: catTextPrimary),
        bodyLarge: t.bodyLarge?.copyWith(color: catTextPrimary),
        bodyMedium: t.bodyMedium?.copyWith(color: catTextPrimary),
        bodySmall: t.bodySmall?.copyWith(color: catTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: catSurface,
        foregroundColor: catTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(color: catTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: catSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: catDivider),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: catSurface,
        selectedItemColor: catPrimary,
        unselectedItemColor: catTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: catPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: catBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: catDivider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: catDivider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: catPrimary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.fredoka(color: catTextSecondary),
        hintStyle: GoogleFonts.fredoka(color: catTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: catPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: catPrimary, textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Cat dark 🐱 ──────────────────────────────────────────────────────────────
  static ThemeData get catDarkTheme {
    final t = _nunitoTextTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: catDarkPrimary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF3D2020),
        onPrimaryContainer: catDarkTextPrimary,
        secondary: catDarkTextSecondary,
        onSecondary: catDarkBackground,
        secondaryContainer: catDarkDivider,
        onSecondaryContainer: catDarkTextPrimary,
        tertiary: catDarkTextSecondary,
        onTertiary: catDarkBackground,
        surface: catDarkSurface,
        onSurface: catDarkTextPrimary,
        surfaceContainerHighest: catDarkBackground,
        outline: catDarkDivider,
        error: Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: catDarkBackground,
      textTheme: t.copyWith(
        displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: catDarkTextPrimary),
        displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: catDarkTextPrimary),
        displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: catDarkTextPrimary),
        headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: catDarkTextPrimary),
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: catDarkTextPrimary),
        headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: catDarkTextPrimary),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: catDarkTextPrimary),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: catDarkTextPrimary),
        titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: catDarkTextPrimary),
        bodyLarge: t.bodyLarge?.copyWith(color: catDarkTextPrimary),
        bodyMedium: t.bodyMedium?.copyWith(color: catDarkTextPrimary),
        bodySmall: t.bodySmall?.copyWith(color: catDarkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: catDarkSurface,
        foregroundColor: catDarkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(color: catDarkTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: catDarkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: catDarkDivider),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: catDarkSurface,
        selectedItemColor: catDarkPrimary,
        unselectedItemColor: catDarkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: catDarkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: catDarkBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: catDarkDivider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: catDarkDivider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: catDarkPrimary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.fredoka(color: catDarkTextSecondary),
        hintStyle: GoogleFonts.fredoka(color: catDarkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: catDarkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: catDarkPrimary, textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700)),
      ),
    );
  }
}









