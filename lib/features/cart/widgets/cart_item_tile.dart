import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/cart_item_model.dart';

/// Individual cart item tile with quantity stepper and swipe-to-delete hint.
class CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onQtyChanged;

  const CartItemTile({
    super.key,
    required this.item,
    this.onRemove,
    this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(11),
              bottomLeft: Radius.circular(11),
            ),
            child: SizedBox(
              width: 80,
              height: 80,
              child: item.image.isNotEmpty
                  ? Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: context.colors.primaryLight,
                        child: Icon(Icons.image_not_supported_rounded,
                            color: context.colors.border),
                      ),
                    )
                  : Container(
                      color: context.colors.primaryLight,
                      child: Icon(
                        Icons.edit_rounded,
                        size: 32,
                        color: context.colors.primary.withValues(alpha: 0.6),
                      ),
                    ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppFormatters.formatPrice(item.price * item.qty),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.colors.primary,
                        ),
                      ),
                      // Quantity stepper
                      _QtyStepper(
                        qty: item.qty,
                        maxQty: item.stock,
                        onDecrement: () {
                          if (item.qty > 1) {
                            onQtyChanged?.call(item.qty - 1);
                          } else {
                            onRemove?.call();
                          }
                        },
                        onIncrement: () {
                          if (item.qty < item.stock) {
                            onQtyChanged?.call(item.qty + 1);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline_rounded,
                color: context.colors.error, size: 20),
            padding: EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

/// Compact +/- stepper for cart items
class _QtyStepper extends StatelessWidget {
  final int qty;
  final int maxQty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtyStepper({
    required this.qty,
    required this.maxQty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                qty <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                size: 16,
                color: qty <= 1 ? context.colors.error : context.colors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$qty',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: qty < maxQty ? onIncrement : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                Icons.add_rounded,
                size: 16,
                color: qty < maxQty ? context.colors.primary : context.colors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}






