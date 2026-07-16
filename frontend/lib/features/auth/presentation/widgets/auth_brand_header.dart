import 'package:flutter/material.dart';
import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/constants/app_colors.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 85,
          height: 90,
          child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
        ),
        const SizedBox(height: 13),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
