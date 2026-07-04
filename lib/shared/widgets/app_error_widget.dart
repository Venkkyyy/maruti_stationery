import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'app_button.dart';

/// Generic error state widget — shows icon, message, and optional retry button.
/// Named AppErrorWidget to avoid collision with Flutter's built-in ErrorWidget.
class AppErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  /// Shorthand for network errors
  const AppErrorWidget.network({
    super.key,
    this.onRetry,
  })  : title = 'Connection Error',
        message = 'Check your internet connection and try again.',
        icon = Icons.wifi_off_rounded;

  /// Shorthand for not-found
  const AppErrorWidget.notFound({
    super.key,
    this.onRetry,
  })  : title = 'Not Found',
        message = 'The requested content could not be found.',
        icon = Icons.search_off_rounded;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: context.colors.error),
            ),
            const SizedBox(height: 20),
            Text(
              title ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'An unexpected error occurred. Please try again.',
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton.outlined(
                text: 'Try Again',
                onPressed: onRetry,
                width: 140,
                height: 44,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}






