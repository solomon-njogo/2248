import 'package:flutter/painting.dart';

abstract final class AppColors {
  static const night = Color(0xff1a1464);
  static const well = Color(0xff24185a);
  static const floor = Color(0xff1a1048);
  static const chip = Color(0xff2a1d78);
  static const mist = Color(0xffb7b7d6);
  static const ink = Color(0xff1a1a2e);
  static const magenta = Color(0xffff2d8a);

  static const tile2 = Color(0xffff2d8a);
  static const tile4 = Color(0xff19e0ff);
  static const tile8 = Color(0xffc6f22a);
  static const tile16 = Color(0xffff7a18);
  static const tile32 = Color(0xff3d6bff);
  static const tile64 = Color(0xffffe14a);
  static const tile128 = Color(0xffb44dff);
  static const tile256 = Color(0xffff4d4d);
  static const tile512 = Color(0xff2ef2a0);
  static const tile1024 = Color(0xffff4fd8);
}

const _ladder = <int, Color>{
  2: AppColors.tile2,
  4: AppColors.tile4,
  8: AppColors.tile8,
  16: AppColors.tile16,
  32: AppColors.tile32,
  64: AppColors.tile64,
  128: AppColors.tile128,
  256: AppColors.tile256,
  512: AppColors.tile512,
  1024: AppColors.tile1024,
};

const _goldenAngle = 137.50776405003785;

Color tileColor(int value) {
  final known = _ladder[value];
  if (known != null) return known;
  final stepsAbove1024 = _log2(value) - 10;
  final magenta = HSLColor.fromColor(AppColors.magenta);
  final hue = (magenta.hue + stepsAbove1024 * _goldenAngle) % 360;
  return magenta.withHue(hue < 0 ? hue + 360 : hue).toColor();
}

Color numeralColor(int value) {
  if (value == 8 || value == 64) return AppColors.ink;
  if (value <= 1024) return const Color(0xffffffff);
  final lightness = HSLColor.fromColor(tileColor(value)).lightness;
  final lime = HSLColor.fromColor(AppColors.tile8).lightness;
  if (lightness >= lime) return AppColors.ink;
  return const Color(0xffffffff);
}

int _log2(int value) {
  var power = 1;
  var exponent = 0;
  while (power < value) {
    power *= 2;
    exponent++;
  }
  return exponent;
}
