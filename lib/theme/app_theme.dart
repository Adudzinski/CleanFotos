import 'package:flutter/material.dart';

/// App colors and themes with light + dark palettes.
///
/// Screens reference colors as `AppTheme.surface`, `AppTheme.textPrimary`,
/// etc. Those are getters that switch on [isDark], which the app root sets
/// before every build (see main.dart). Because the getters aren't const,
/// widgets using them must not be const-constructed.
class AppTheme {
  // Brand colors — identical in both modes.
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42D6);
  static const Color secondary = Color(0xFFFF6584);
  static const Color success = Color(0xFF43D17A);
  static const Color danger = Color(0xFFFF4757);

  /// Set by the app root before building, from the theme preference and the
  /// system brightness.
  static bool isDark = false;

  // Light palette
  static const Color _lBackground = Color(0xFFF4F3FF);
  static const Color _lSurface = Color(0xFFFFFFFF);
  static const Color _lTextPrimary = Color(0xFF1A1A2E);
  static const Color _lTextSecondary = Color(0xFF6B6B8A);
  static const Color _lDivider = Color(0xFFF0F0F4);
  static const Color _lCardShadow = Color(0x1A6C63FF);

  // Dark palette
  static const Color _dBackground = Color(0xFF131220);
  static const Color _dSurface = Color(0xFF1E1C2E);
  static const Color _dTextPrimary = Color(0xFFF1F0FA);
  static const Color _dTextSecondary = Color(0xFFA8A6C4);
  static const Color _dDivider = Color(0xFF2A2840);
  static const Color _dCardShadow = Color(0x40000000);

  static Color get background => isDark ? _dBackground : _lBackground;
  static Color get surface => isDark ? _dSurface : _lSurface;
  static Color get textPrimary => isDark ? _dTextPrimary : _lTextPrimary;
  static Color get textSecondary =>
      isDark ? _dTextSecondary : _lTextSecondary;
  static Color get divider => isDark ? _dDivider : _lDivider;
  static Color get cardShadow => isDark ? _dCardShadow : _lCardShadow;

  static ThemeData get lightTheme => _theme(Brightness.light);
  static ThemeData get darkTheme => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final bg = dark ? _dBackground : _lBackground;
    final surf = dark ? _dSurface : _lSurface;
    final tp = dark ? _dTextPrimary : _lTextPrimary;
    final ts = dark ? _dTextSecondary : _lTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surf,
        error: danger,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: tp,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: tp,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: tp,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: tp,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: tp,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: tp,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: tp,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ts,
        ),
        labelLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surf,
        foregroundColor: tp,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: tp,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: dark ? _dCardShadow : _lCardShadow,
      ),
    );
  }
}
