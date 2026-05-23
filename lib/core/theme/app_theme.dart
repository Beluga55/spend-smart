import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_expense_tracker/core/providers/font_provider.dart';

@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color income;
  final Color expense;
  final Color warning;

  const SemanticColors({
    required this.success,
    required this.income,
    required this.expense,
    required this.warning,
  });

  @override
  SemanticColors copyWith({
    Color? success,
    Color? income,
    Color? expense,
    Color? warning,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
    );
  }

  @override
  SemanticColors lerp(SemanticColors? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

class AppTheme {
  // ── Default palette ─────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF000000);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);

  static const Color darkBackgroundColor = Color(0xFF1A1A1A);
  static const Color darkSurfaceColor = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkDividerColor = Color(0xFF404040);
  static const Color darkSuccessColor = Color(0xFF81C784);
  static const Color darkWarningColor = Color(0xFFFFB74D);

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

  // ── Lime palette ─────────────────────────────────────────────────────────────
  static const Color limePrimary = Color(0xFF4CAF50);
  static const Color limeBackground = Color(0xFFF1F8E9);
  static const Color limeSurface = Color(0xFFFFFFFF);
  static const Color limeTextPrimary = Color(0xFF1B5E20);
  static const Color limeTextSecondary = Color(0xFF455A64);
  static const Color limeDivider = Color(0xFFC8E6C9);

  static const Color limeDarkPrimary = Color(0xFF8EF13E);
  static const Color limeDarkBackground = Color(0xFF1A1A1A);
  static const Color limeDarkSurface = Color(0xFF2D2D2D);
  static const Color limeDarkTextPrimary = Color(0xFFFFFFFF);
  static const Color limeDarkTextSecondary = Color(0xFFA0A0A0);
  static const Color limeDarkDivider = Color(0xFF404040);

  // ── Text themes ─────────────────────────────────────────────────────────────
  static TextTheme _getTextTheme(FontFamily fontFamily) {
    switch (fontFamily) {
      case FontFamily.sora:
        return GoogleFonts.soraTextTheme();
      case FontFamily.fredoka:
        return GoogleFonts.fredokaTextTheme();
      case FontFamily.comfortaa:
        return GoogleFonts.comfortaaTextTheme();
    }
  }

  static TextStyle _font(
    FontFamily fontFamily, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    switch (fontFamily) {
      case FontFamily.sora:
        return GoogleFonts.sora(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case FontFamily.fredoka:
        return GoogleFonts.fredoka(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case FontFamily.comfortaa:
        return GoogleFonts.comfortaa(fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }

  // ── Default light ────────────────────────────────────────────────────────────
  static ThemeData lightTheme({FontFamily fontFamily = FontFamily.sora}) {
    final textTheme = _getTextTheme(fontFamily);
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
        surfaceContainerHighest: Color(0xFFF5F5F5),
        surfaceContainerLow: Color(0xFFF0F0F0),
        outline: dividerColor,
        outlineVariant: Color(0xFFE8E8E8),
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
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
        selectedLabelStyle: _font(fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: _font(fontFamily, fontSize: 11),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _font(fontFamily, color: textSecondary),
        hintStyle: _font(fontFamily, color: textSecondary),
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
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        titleTextStyle: _font(fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        contentTextStyle: _font(fontFamily, color: textPrimary),
      ),
      extensions: const [
        SemanticColors(
          success: successColor,
          income: successColor,
          expense: errorColor,
          warning: warningColor,
        ),
      ],
    );
  }

  // ── Default dark ─────────────────────────────────────────────────────────────
  static ThemeData darkTheme({FontFamily fontFamily = FontFamily.sora}) {
    final textTheme = _getTextTheme(fontFamily);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        surface: darkSurfaceColor,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: Color(0xFF333333),
        surfaceContainerLow: Color(0xFF2A2A2A),
        outline: darkDividerColor,
        outlineVariant: Color(0xFF454545),
        error: Color(0xFFEF5350),
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: darkTextPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: darkTextPrimary),
        bodySmall: textTheme.bodySmall?.copyWith(color: darkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
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
        selectedLabelStyle: _font(fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: _font(fontFamily, fontSize: 11),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _font(fontFamily, color: darkTextSecondary),
        hintStyle: _font(fontFamily, color: darkTextSecondary),
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
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceColor,
        titleTextStyle: _font(fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: darkTextPrimary),
        contentTextStyle: _font(fontFamily, color: darkTextPrimary),
      ),
      extensions: const [
        SemanticColors(
          success: darkSuccessColor,
          income: darkSuccessColor,
          expense: Color(0xFFEF5350),
          warning: darkWarningColor,
        ),
      ],
    );
  }

  // ── Cat light 🐱 ─────────────────────────────────────────────────────────────
  static ThemeData catLightTheme({FontFamily fontFamily = FontFamily.fredoka}) {
    final t = _getTextTheme(fontFamily);
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
        surfaceContainerHighest: Color(0xFFFDF0E6),
        surfaceContainerLow: catBackground,
        outline: catDivider,
        outlineVariant: Color(0xFFF0E0D0),
        error: Color(0xFFB00020),
      ),
      scaffoldBackgroundColor: catBackground,
      textTheme: t.copyWith(
        displayLarge: t.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: catTextPrimary,
        ),
        displayMedium: t.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: catTextPrimary,
        ),
        displaySmall: t.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: catTextPrimary,
        ),
        headlineLarge: t.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: catTextPrimary,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: catTextPrimary,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: catTextPrimary,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: catTextPrimary,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: catTextPrimary,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: catTextPrimary,
        ),
        bodyLarge: t.bodyLarge?.copyWith(color: catTextPrimary),
        bodyMedium: t.bodyMedium?.copyWith(color: catTextPrimary),
        bodySmall: t.bodySmall?.copyWith(color: catTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: catSurface,
        foregroundColor: catTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: catTextPrimary),
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
        selectedLabelStyle: _font(fontFamily, fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: _font(fontFamily, fontSize: 11),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: catDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: catDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: catPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _font(fontFamily, color: catTextSecondary),
        hintStyle: _font(fontFamily, color: catTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: catPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: _font(fontFamily, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: catPrimary,
          textStyle: _font(fontFamily, fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: catSurface,
        titleTextStyle: _font(fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: catTextPrimary),
        contentTextStyle: _font(fontFamily, color: catTextPrimary),
      ),
      extensions: const [
        SemanticColors(
          success: successColor,
          income: successColor,
          expense: errorColor,
          warning: warningColor,
        ),
      ],
    );
  }

  // ── Cat dark 🐱 ──────────────────────────────────────────────────────────────
  static ThemeData catDarkTheme({FontFamily fontFamily = FontFamily.fredoka}) {
    final t = _getTextTheme(fontFamily);
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
        surfaceContainerHighest: Color(0xFF332A2D),
        surfaceContainerLow: catDarkBackground,
        outline: catDarkDivider,
        outlineVariant: Color(0xFF4A3F43),
        error: Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: catDarkBackground,
      textTheme: t.copyWith(
        displayLarge: t.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: catDarkTextPrimary,
        ),
        displayMedium: t.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: catDarkTextPrimary,
        ),
        displaySmall: t.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: catDarkTextPrimary,
        ),
        headlineLarge: t.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: catDarkTextPrimary,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: catDarkTextPrimary,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: catDarkTextPrimary,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: catDarkTextPrimary,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: catDarkTextPrimary,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: catDarkTextPrimary,
        ),
        bodyLarge: t.bodyLarge?.copyWith(color: catDarkTextPrimary),
        bodyMedium: t.bodyMedium?.copyWith(color: catDarkTextPrimary),
        bodySmall: t.bodySmall?.copyWith(color: catDarkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: catDarkSurface,
        foregroundColor: catDarkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: catDarkTextPrimary),
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
        selectedLabelStyle: _font(fontFamily, fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: _font(fontFamily, fontSize: 11),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: catDarkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: catDarkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: catDarkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _font(fontFamily, color: catDarkTextSecondary),
        hintStyle: _font(fontFamily, color: catDarkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: catDarkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: _font(fontFamily, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: catDarkPrimary,
          textStyle: _font(fontFamily, fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: catDarkSurface,
        titleTextStyle: _font(fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: catDarkTextPrimary),
        contentTextStyle: _font(fontFamily, color: catDarkTextPrimary),
      ),
      extensions: const [
        SemanticColors(
          success: darkSuccessColor,
          income: darkSuccessColor,
          expense: Color(0xFFCF6679),
          warning: darkWarningColor,
        ),
      ],
    );
  }

  // ── Lime light 💚 ─────────────────────────────────────────────────────────────
  static ThemeData limeLightTheme({FontFamily fontFamily = FontFamily.comfortaa}) {
    final t = _getTextTheme(fontFamily);
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: limePrimary,
        onPrimary: Colors.white,
        surface: limeSurface,
        onSurface: limeTextPrimary,
        surfaceContainerHighest: Color(0xFFE8F5E9),
        surfaceContainerLow: limeBackground,
        outline: limeDivider,
        outlineVariant: Color(0xFFE0E0E0),
        error: Color(0xFFD32F2F),
      ),
      scaffoldBackgroundColor: limeBackground,
      textTheme: t.copyWith(
        displayLarge: t.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: limeTextPrimary,
        ),
        displayMedium: t.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: limeTextPrimary,
        ),
        displaySmall: t.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: limeTextPrimary,
        ),
        headlineLarge: t.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: limeTextPrimary,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: limeTextPrimary,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: limeTextPrimary,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: limeTextPrimary,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: limeTextPrimary,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: limeTextPrimary,
        ),
        bodyLarge: t.bodyLarge?.copyWith(color: limeTextPrimary),
        bodyMedium: t.bodyMedium?.copyWith(color: limeTextPrimary),
        bodySmall: t.bodySmall?.copyWith(color: limeTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: limeSurface,
        foregroundColor: limeTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: limeTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: limeSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: limeDivider),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: limeSurface,
        selectedItemColor: limePrimary,
        unselectedItemColor: limeTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: _font(fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: _font(fontFamily, fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: limePrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: limeBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: limeDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: limeDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: limePrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _font(fontFamily, color: limeTextSecondary),
        hintStyle: _font(fontFamily, color: limeTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: limePrimary,
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: limeSurface,
        titleTextStyle: _font(fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: limeTextPrimary),
        contentTextStyle: _font(fontFamily, color: limeTextPrimary),
      ),
      extensions: const [
        SemanticColors(
          success: limePrimary,
          income: limePrimary,
          expense: Color(0xFFD32F2F),
          warning: Color(0xFFF57C00),
        ),
      ],
    );
  }

  // ── Lime dark 💚 ──────────────────────────────────────────────────────────────
  static ThemeData limeDarkTheme({FontFamily fontFamily = FontFamily.comfortaa}) {
    final t = _getTextTheme(fontFamily);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: limeDarkPrimary,
        onPrimary: Colors.black,
        surface: limeDarkSurface,
        onSurface: limeDarkTextPrimary,
        surfaceContainerHighest: Color(0xFF333333),
        surfaceContainerLow: Color(0xFF2A2A2A),
        outline: limeDarkDivider,
        outlineVariant: Color(0xFF454545),
        error: Color(0xFFEF5350),
      ),
      scaffoldBackgroundColor: limeDarkBackground,
      textTheme: t.copyWith(
        displayLarge: t.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: limeDarkTextPrimary,
        ),
        displayMedium: t.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: limeDarkTextPrimary,
        ),
        displaySmall: t.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: limeDarkTextPrimary,
        ),
        headlineLarge: t.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: limeDarkTextPrimary,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: limeDarkTextPrimary,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: limeDarkTextPrimary,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: limeDarkTextPrimary,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: limeDarkTextPrimary,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: limeDarkTextPrimary,
        ),
        bodyLarge: t.bodyLarge?.copyWith(color: limeDarkTextPrimary),
        bodyMedium: t.bodyMedium?.copyWith(color: limeDarkTextPrimary),
        bodySmall: t.bodySmall?.copyWith(color: limeDarkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: limeDarkSurface,
        foregroundColor: limeDarkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: limeDarkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: limeDarkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: limeDarkDivider),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: limeDarkSurface,
        selectedItemColor: limeDarkPrimary,
        unselectedItemColor: limeDarkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: _font(fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: _font(fontFamily, fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: limeDarkPrimary,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: limeDarkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: limeDarkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: limeDarkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: limeDarkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _font(fontFamily, color: limeDarkTextSecondary),
        hintStyle: _font(fontFamily, color: limeDarkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limeDarkPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: limeDarkPrimary,
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: limeDarkSurface,
        titleTextStyle: _font(fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: limeDarkTextPrimary),
        contentTextStyle: _font(fontFamily, color: limeDarkTextPrimary),
      ),
      extensions: const [
        SemanticColors(
          success: limeDarkPrimary,
          income: limeDarkPrimary,
          expense: Color(0xFFEF5350),
          warning: Color(0xFFFFB74D),
        ),
      ],
    );
  }

  // ── Emerald palette 💎 ───────────────────────────────────────────────────────
  static const Color emeraldPrimary = Color(0xFFA5D6A7);
  static const Color emeraldBackground = Color(0xFFF5F7F5);
  static const Color emeraldSurface = Color(0xFFFFFFFF);
  static const Color emeraldTextPrimary = Color(0xFF1A1A1A);
  static const Color emeraldTextSecondary = Color(0xFF6B7B6B);
  static const Color emeraldDivider = Color(0xFFE0E4E0);

  static const Color emeraldDarkPrimary = Color(0xFFA5D6A7);
  static const Color emeraldDarkBackground = Color(0xFF1A1A1A);
  static const Color emeraldDarkSurface = Color(0xFF252525);
  static const Color emeraldDarkTextPrimary = Color(0xFFE8E8E8);
  static const Color emeraldDarkTextSecondary = Color(0xFFA5D6A7);
  static const Color emeraldDarkDivider = Color(0xFF404040);

  // ── Emerald light 💎 ─────────────────────────────────────────────────────────
  static ThemeData emeraldLightTheme({FontFamily fontFamily = FontFamily.comfortaa}) {
    final t = _getTextTheme(fontFamily);
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: emeraldPrimary,
        onPrimary: Colors.white,
        surface: emeraldSurface,
        onSurface: emeraldTextPrimary,
        surfaceContainerHighest: Color(0xFFEEF0EE),
        surfaceContainerLow: emeraldBackground,
        outline: emeraldDivider,
        outlineVariant: Color(0xFFCDD2CD),
        error: Color(0xFFD32F2F),
      ),
      scaffoldBackgroundColor: emeraldBackground,
      textTheme: t.copyWith(
        displayLarge: t.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: emeraldTextPrimary,
        ),
        displayMedium: t.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: emeraldTextPrimary,
        ),
        displaySmall: t.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: emeraldTextPrimary,
        ),
        headlineLarge: t.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: emeraldTextPrimary,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: emeraldTextPrimary,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: emeraldTextPrimary,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: emeraldTextPrimary,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: emeraldTextPrimary,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: emeraldTextPrimary,
        ),
        bodyLarge: t.bodyLarge?.copyWith(color: emeraldTextPrimary),
        bodyMedium: t.bodyMedium?.copyWith(color: emeraldTextPrimary),
        bodySmall: t.bodySmall?.copyWith(color: emeraldTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: emeraldSurface,
        foregroundColor: emeraldTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: emeraldTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: emeraldSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: emeraldDivider),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: emeraldSurface,
        selectedItemColor: emeraldPrimary,
        unselectedItemColor: emeraldTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: _font(fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: _font(fontFamily, fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emeraldPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: emeraldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _font(fontFamily, color: emeraldTextSecondary),
        hintStyle: _font(fontFamily, color: emeraldTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: emeraldPrimary,
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: emeraldSurface,
        titleTextStyle: _font(fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: emeraldTextPrimary),
        contentTextStyle: _font(fontFamily, color: emeraldTextPrimary),
      ),
      extensions: const [
        SemanticColors(
          success: emeraldPrimary,
          income: emeraldPrimary,
          expense: Color(0xFFE57373),
          warning: Color(0xFFFFB74D),
        ),
      ],
    );
  }

  // ── Emerald dark 💎 ───────────────────────────────────────────────────────────
  static ThemeData emeraldDarkTheme({FontFamily fontFamily = FontFamily.comfortaa}) {
    final t = _getTextTheme(fontFamily);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: emeraldDarkPrimary,
        onPrimary: Colors.black,
        surface: emeraldDarkSurface,
        onSurface: emeraldDarkTextPrimary,
        surfaceContainerHighest: Color(0xFF2A2A2A),
        surfaceContainerLow: emeraldDarkBackground,
        outline: emeraldDarkDivider,
        outlineVariant: Color(0xFF383838),
        error: Color(0xFFEF5350),
      ),
      scaffoldBackgroundColor: emeraldDarkBackground,
      textTheme: t.copyWith(
        displayLarge: t.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: emeraldDarkTextPrimary,
        ),
        displayMedium: t.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: emeraldDarkTextPrimary,
        ),
        displaySmall: t.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: emeraldDarkTextPrimary,
        ),
        headlineLarge: t.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: emeraldDarkTextPrimary,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: emeraldDarkTextPrimary,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: emeraldDarkTextPrimary,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: emeraldDarkTextPrimary,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: emeraldDarkTextPrimary,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: emeraldDarkTextPrimary,
        ),
        bodyLarge: t.bodyLarge?.copyWith(color: emeraldDarkTextPrimary),
        bodyMedium: t.bodyMedium?.copyWith(color: emeraldDarkTextPrimary),
        bodySmall: t.bodySmall?.copyWith(color: emeraldDarkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: emeraldDarkSurface,
        foregroundColor: emeraldDarkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: emeraldDarkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: emeraldDarkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: emeraldDarkDivider),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: emeraldDarkSurface,
        selectedItemColor: emeraldDarkPrimary,
        unselectedItemColor: emeraldDarkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: _font(fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: _font(fontFamily, fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emeraldDarkPrimary,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: emeraldDarkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldDarkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldDarkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldDarkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _font(fontFamily, color: emeraldDarkTextSecondary),
        hintStyle: _font(fontFamily, color: emeraldDarkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldDarkPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: emeraldDarkPrimary,
          textStyle: _font(fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: emeraldDarkSurface,
        titleTextStyle: _font(fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: emeraldDarkTextPrimary),
        contentTextStyle: _font(fontFamily, color: emeraldDarkTextPrimary),
      ),
      extensions: const [
        SemanticColors(
          success: emeraldDarkPrimary,
          income: emeraldDarkPrimary,
          expense: Color(0xFFF87171),
          warning: Color(0xFFFBBF24),
        ),
      ],
    );
  }
}
