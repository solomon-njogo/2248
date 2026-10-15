import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTextStyles.family,
    scaffoldBackgroundColor: AppColors.night,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.night,
      primary: AppColors.magenta,
      onPrimary: Color(0xffffffff),
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: AppTextStyles.family),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.chip,
      titleTextStyle: AppTextStyles.dialogTitle,
      contentTextStyle: AppTextStyles.body,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.magenta,
        foregroundColor: const Color(0xffffffff),
        minimumSize: const Size(48, 48),
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xffffffff),
        minimumSize: const Size(48, 48),
        textStyle: AppTextStyles.body,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
