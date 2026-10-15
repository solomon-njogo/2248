import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const family = 'Plus Jakarta Sans';

  static const wordmark = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 1.1,
    color: Color(0xffffffff),
  );

  static const dialogTitle = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.2,
    color: Color(0xffffffff),
  );

  static const score = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 22,
    height: 1.1,
    color: Color(0xffffffff),
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const label = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 0.4,
    color: AppColors.mist,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.35,
    color: Color(0xffffffff),
  );

  static const tile = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 64,
    height: 1,
  );
}
