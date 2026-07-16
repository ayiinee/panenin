import 'package:flutter/material.dart';
import 'package:panenin/core/constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    fontFamily: 'Inter',
    scaffoldBackgroundColor: Colors.white,
  );
}
