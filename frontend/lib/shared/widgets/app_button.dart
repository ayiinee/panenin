import 'package:flutter/material.dart';
import 'package:panenin/app/theme/app_colors.dart';

enum AppButtonVariant { primary, accent, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  Color get _backgroundColor => switch (variant) {
    AppButtonVariant.primary => AppColors.primary,
    AppButtonVariant.accent => AppColors.accent,
    AppButtonVariant.danger => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _backgroundColor,
          disabledBackgroundColor: _backgroundColor.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(
            fontSize: variant == AppButtonVariant.primary ? 14 : 13,
            fontWeight: variant == AppButtonVariant.primary
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
