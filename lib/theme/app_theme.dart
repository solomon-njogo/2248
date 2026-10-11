import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: AppColors.primary.withValues(alpha: 0.06),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.ink,
        secondary: AppColors.secondary,
        onSecondary: AppColors.text,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.danger,
        onError: AppColors.text,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.title,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.hint,
        labelLarge: AppTextStyles.button,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.primaryDim,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppTextStyles.button,
          side: const BorderSide(color: AppColors.surfaceBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.surface.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}
