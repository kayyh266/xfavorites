import 'package:flutter/material.dart';

/// Bảng màu duy nhất của ứng dụng (chỉ giao diện tối).
class AppColors {
  AppColors._();

  /// Nền chính xám xanh đậm.
  static const Color background = Color(0xFF252A34);

  /// Bề mặt thẻ.
  static const Color surface = Color(0xFF2B313D);

  /// Bề mặt nổi hơn (menu, dialog, toast).
  static const Color surfaceRaised = Color(0xFF303744);

  /// Bề mặt lõm (ô nhập, rãnh thanh tiến trình).
  static const Color surfaceSunken = Color(0xFF21252E);

  /// Chữ chính.
  static const Color textPrimary = Color(0xFFE8ECF1);

  /// Chữ phụ.
  static const Color textSecondary = Color(0xFF9AA3B2);

  /// Chữ mờ.
  static const Color textMuted = Color(0xFF6F7889);

  /// Màu nhấn xanh ngọc.
  static const Color accent = Color(0xFF2EC4B6);

  /// Xanh ngọc đậm (dùng cho gradient).
  static const Color accentDeep = Color(0xFF1B8F85);

  /// Màu phụ cam.
  static const Color orange = Color(0xFFF5A524);

  /// Màu nguy hiểm.
  static const Color danger = Color(0xFFE5484D);

  /// Viền mờ.
  static const Color outline = Color(0xFF3A4250);

  /// Chữ tối dùng trên nền xanh ngọc/cam.
  static const Color onBright = Color(0xFF10201E);
}

/// Hai lớp bóng đổ neumorphism dùng lại trong toàn bộ giao diện.
class AppShadows {
  AppShadows._();

  /// Bóng đầy đủ cho thẻ lớn: tối dưới-phải + sáng trên-trái.
  static const List<BoxShadow> neu = [
    BoxShadow(
      color: Color(0x73000000),
      offset: Offset(6, 6),
      blurRadius: 14,
    ),
    BoxShadow(
      color: Color(0x0AFFFFFF),
      offset: Offset(-4, -4),
      blurRadius: 10,
    ),
  ];

  /// Bóng nhẹ cho danh sách dài (hàng trăm đến vài nghìn dòng).
  static const List<BoxShadow> neuSoft = [
    BoxShadow(
      color: Color(0x4D000000),
      offset: Offset(3, 3),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x08FFFFFF),
      offset: Offset(-2, -2),
      blurRadius: 6,
    ),
  ];

  /// Bóng khi nhấn (cảm giác lún xuống).
  static const List<BoxShadow> neuPressed = [
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(1, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x05FFFFFF),
      offset: Offset(-1, -1),
      blurRadius: 2,
    ),
  ];
}

/// Theme tối duy nhất của X Favorites.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onBright,
      primaryContainer: AppColors.accentDeep,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.orange,
      onSecondary: AppColors.onBright,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceRaised,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimary),
        bodyMedium: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSunken,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF323947)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 14,
        iconColor: AppColors.textSecondary,
        textStyle: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF343B48),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outline),
        ),
        textStyle: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.textMuted.withValues(alpha: 0.55),
        ),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onBright,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.outline),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceSunken,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
