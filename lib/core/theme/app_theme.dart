import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maruti_stationery/core/constants/app_text_styles.dart';

class AppThemeColors {
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceGrey;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color error;
  final Color errorLight;
  final Color success;
  final Color warning;

  const AppThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceGrey,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.error,
    required this.errorLight,
    required this.success,
    required this.warning,
  });
}

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppThemeColors colors;
  const AppThemeExtension({required this.colors});

  @override
  ThemeExtension<AppThemeExtension> copyWith({AppThemeColors? colors}) {
    return AppThemeExtension(colors: colors ?? this.colors);
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(covariant ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      colors: AppThemeColors(
        primary: Color.lerp(colors.primary, other.colors.primary, t)!,
        primaryLight: Color.lerp(colors.primaryLight, other.colors.primaryLight, t)!,
        secondary: Color.lerp(colors.secondary, other.colors.secondary, t)!,
        background: Color.lerp(colors.background, other.colors.background, t)!,
        surface: Color.lerp(colors.surface, other.colors.surface, t)!,
        surfaceGrey: Color.lerp(colors.surfaceGrey, other.colors.surfaceGrey, t)!,
        textPrimary: Color.lerp(colors.textPrimary, other.colors.textPrimary, t)!,
        textSecondary: Color.lerp(colors.textSecondary, other.colors.textSecondary, t)!,
        textHint: Color.lerp(colors.textHint, other.colors.textHint, t)!,
        border: Color.lerp(colors.border, other.colors.border, t)!,
        divider: Color.lerp(colors.divider, other.colors.divider, t)!,
        error: Color.lerp(colors.error, other.colors.error, t)!,
        errorLight: Color.lerp(colors.errorLight, other.colors.errorLight, t)!,
        success: Color.lerp(colors.success, other.colors.success, t)!,
        warning: Color.lerp(colors.warning, other.colors.warning, t)!,
      ),
    );
  }
}

class AppTheme {
  // ── Light Colors ─────────────────────────────────────────────────────────
  static const AppThemeColors _lightColors = AppThemeColors(
    primary: Color(0xFF1A73E8),
    primaryLight: Color(0xFFE8F0FE),
    secondary: Color(0xFFE8F0FE),
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    surfaceGrey: Color(0xFFF1F3F4),
    textPrimary: Color(0xFF202124),
    textSecondary: Color(0xFF5F6368),
    textHint: Color(0xFF9AA0A6),
    border: Color(0xFFE8EAED),
    divider: Color(0xFFF1F3F4),
    error: Color(0xFFEA4335),
    errorLight: Color(0xFFFCE8E6),
    success: Color(0xFF34A853),
    warning: Color(0xFFFBBC05),
  );

  // ── Dark Colors ──────────────────────────────────────────────────────────
  static const AppThemeColors _darkColors = AppThemeColors(
    primary: Color(0xFF8AB4F8),
    primaryLight: Color(0xFF1F2B4C),
    secondary: Color(0xFF303C5C),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceGrey: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFE8EAED),
    textSecondary: Color(0xFF9AA0A6),
    textHint: Color(0xFF5F6368),
    border: Color(0xFF3C4043),
    divider: Color(0xFF2D2E30),
    error: Color(0xFFF28B82),
    errorLight: Color(0xFF3B1E1E),
    success: Color(0xFF81C995),
    warning: Color(0xFFFDE293),
  );

  // Helper method to generate themes
  static ThemeData _buildTheme(AppThemeColors colors, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
        primary: colors.primary,
        onPrimary: brightness == Brightness.light ? Colors.white : Colors.black,
        secondary: colors.primaryLight,
        onSecondary: colors.primary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: colors.textPrimary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: colors.textPrimary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: colors.textPrimary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: colors.textPrimary),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: colors.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: colors.textPrimary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: colors.textPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: colors.textPrimary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: colors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colors.border,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.primary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.light ? Brightness.dark : Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: brightness == Brightness.light ? Colors.white : Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colors.textHint, fontSize: 14),
        labelStyle: TextStyle(color: colors.textSecondary),
        floatingLabelStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        side: BorderSide(color: colors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        space: 1,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      extensions: [
        AppThemeExtension(colors: colors),
      ],
    );
  }

  static ThemeData lightTheme = _buildTheme(_lightColors, Brightness.light);
  static ThemeData darkTheme = _buildTheme(_darkColors, Brightness.dark);
}

extension AppThemeContextExtension on BuildContext {
  AppThemeColors get colors => Theme.of(this).extension<AppThemeExtension>()!.colors;
}
