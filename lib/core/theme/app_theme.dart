import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// [fontFamily] bypasses runtime font fetching (used for offline screenshot renders).
  static ThemeData light({String? fontFamily}) {
    TextStyle font({double? fontSize, FontWeight? fontWeight, Color? color, double? height}) =>
        fontFamily != null
            ? TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: fontWeight, color: color, height: height)
            : GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    final text = (fontFamily != null
            ? base.textTheme.apply(fontFamily: fontFamily)
            : GoogleFonts.plusJakartaSansTextTheme(base.textTheme))
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
        .copyWith(
          headlineSmall: font(
              fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text),
          titleLarge: font(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
          titleMedium: font(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
          titleSmall: font(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
          bodyMedium: font(
              fontSize: 15, height: 1.45, color: AppColors.text),
          bodySmall: font(
              fontSize: 13, color: AppColors.textMuted),
          labelLarge: font(
              fontSize: 15, fontWeight: FontWeight.w700),
        );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.text,
        titleTextStyle: text.titleMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: text.bodyMedium?.copyWith(color: const Color(0xFFA9A6BC)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: inputBorder.copyWith(
            borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: inputBorder.copyWith(
            borderSide:
                const BorderSide(color: AppColors.danger, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: .45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.hero))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.hero)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
