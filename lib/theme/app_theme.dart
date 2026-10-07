import 'package:flutter/material.dart';
import 'noir.dart';

/// Material theme + legacy colour names.
///
/// Since 1.3 the app is dark-only (Noir, see noir.dart). The getters below are
/// kept so older call sites still compile, and simply return the Noir values.
/// New code should use [Noir] / [NoirText] directly.
class AppTheme {
  static const Color primary = Noir.accentStrong;
  static const Color primaryDark = Noir.text;
  static const Color secondary = Noir.muted;
  static const Color success = Color(0xFF43D17A);
  static const Color danger = Noir.danger;

  /// Always true — kept for older call sites.
  static bool isDark = true;

  static Color get background => Noir.bg;
  static Color get surface => Noir.surface;
  static Color get textPrimary => Noir.text;
  static Color get textSecondary => Noir.muted;
  static Color get divider => Noir.line;
  static Color get cardShadow => const Color(0x40000000);

  /// Both build the same Noir theme — there is no light mode any more.
  static ThemeData get lightTheme => noirTheme;
  static ThemeData get darkTheme => noirTheme;

  static final ThemeData noirTheme = _build();

  static ThemeData _build() {
    const pill = StadiumBorder();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: NoirText.family,
      colorScheme: const ColorScheme.dark(
        primary: Noir.accentStrong,
        onPrimary: Noir.onAccent,
        secondary: Noir.muted,
        onSecondary: Noir.bg,
        surface: Noir.surface,
        onSurface: Noir.text,
        error: Noir.danger,
        onError: Colors.white,
        outline: Noir.line,
      ),
      scaffoldBackgroundColor: Noir.bg,
      canvasColor: Noir.bg,
      dividerColor: Noir.line,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: NoirText.display,
        displayMedium: NoirText.h1,
        headlineLarge: NoirText.h2,
        headlineMedium: NoirText.h2,
        titleLarge: NoirText.bar,
        titleMedium: NoirText.body.copyWith(fontWeight: FontWeight.w500),
        bodyLarge: NoirText.body,
        bodyMedium: NoirText.bodyMuted,
        bodySmall: NoirText.caption,
        labelLarge: NoirText.button,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Noir.bg,
        foregroundColor: Noir.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: NoirText.bar,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Noir.accentStrong,
          foregroundColor: Noir.onAccent,
          minimumSize: const Size(64, 52),
          shape: pill,
          textStyle: NoirText.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Noir.text,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: Noir.line),
          shape: pill,
          textStyle: NoirText.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Noir.text,
          shape: pill,
          textStyle: NoirText.button.copyWith(fontSize: 16),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Noir.accent,
        linearTrackColor: Noir.surface2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Noir.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Noir.rCard),
          side: const BorderSide(color: Noir.line),
        ),
        titleTextStyle: NoirText.h2,
        contentTextStyle: NoirText.bodyMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Noir.surface2,
        contentTextStyle: NoirText.body,
        actionTextColor: Noir.text,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Noir.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Noir.rCard)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Noir.accent
                : Noir.surface2),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.transparent
                : Noir.line),
      ),
      cardTheme: CardThemeData(
        color: Noir.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Noir.rCard),
          side: const BorderSide(color: Noir.line),
        ),
      ),
    );
  }
}
