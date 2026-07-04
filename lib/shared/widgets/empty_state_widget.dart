import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'app_button.dart';

/// Generic empty-state widget with illustration, message, and optional CTA.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.iconColor,
    this.iconBgColor,
    this.buttonText,
    this.onButtonPressed,
  });

  /// Empty cart
  EmptyStateWidget.cart({super.key, this.onButtonPressed})
      : title = 'Your bag is empty',
        subtitle = 'Add items to get started',
        icon = Icons.shopping_bag_outlined,
        iconColor = AppColors.primary,
        iconBgColor = AppColors.primaryLight,
        buttonText = 'Browse Catalog';

  /// Empty wishlist
  EmptyStateWidget.wishlist({super.key, this.onButtonPressed})
      : title = 'Your wishlist is empty',
        subtitle = 'Save items you love to buy later',
        icon = Icons.favorite_border_rounded,
        iconColor = AppColors.error,
        iconBgColor = AppColors.errorLight,
        buttonText = 'Explore Products';

  /// Empty orders
  EmptyStateWidget.orders({super.key, this.onButtonPressed})
      : title = 'No orders yet',
        subtitle = 'Your order history will appear here',
        icon = Icons.receipt_long_outlined,
        iconColor = AppColors.primary,
        iconBgColor = AppColors.primaryLight,
        buttonText = 'Shop Now';

  /// No search results
  EmptyStateWidget.search({super.key, this.onButtonPressed})
      : title = 'No results found',
        subtitle = 'Try different keywords or browse categories',
        icon = Icons.search_off_rounded,
        iconColor = AppColors.textSecondary,
        iconBgColor = AppColors.surfaceGrey,
        buttonText = null;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: iconBgColor ?? context.colors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: iconColor ?? context.colors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                variant: AppButtonVariant.primary,
                width: 180,
                height: 46,
              ),
            ],
          ],
        ),
      ),
    );
  }
}





