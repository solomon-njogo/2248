import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const display = TextStyle(
    fontSize: 52,
    height: 0.92,
    fontWeight: FontWeight.w800,
    letterSpacing: 4,
    color: AppColors.text,
    shadows: [Shadow(color: Color(0xCC070910), blurRadius: 18)],
  );

  static const wordmark = TextStyle(
    fontSize: 18,
    height: 1,
    fontWeight: FontWeight.w700,
    letterSpacing: 8,
    color: AppColors.primary,
  );

  static const eyebrow = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
    color: AppColors.primary,
  );

  static const title = TextStyle(
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const score = TextStyle(
    fontSize: 36,
    height: 1,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const scoreLarge = TextStyle(
    fontSize: 56,
    height: 1,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const combo = TextStyle(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    color: AppColors.accent,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const hint = TextStyle(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const label = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppColors.text,
  );

  static const button = TextStyle(
    fontSize: 16,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
  );
}
