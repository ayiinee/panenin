import 'package:flutter/material.dart';
import 'package:panenin/app/theme/app_colors.dart';

enum AppNotificationType { success, error }

class AppNotificationCard extends StatelessWidget {
  const AppNotificationCard({
    required this.title,
    required this.message,
    required this.type,
    super.key,
  });

  final String title;
  final String message;
  final AppNotificationType type;

  bool get _isSuccess => type == AppNotificationType.success;

  @override
  Widget build(BuildContext context) {
    final accentColor = _isSuccess ? AppColors.primary : AppColors.danger;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F111827),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
