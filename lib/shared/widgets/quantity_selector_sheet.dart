import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../core/utils/formatters.dart';

class QuantitySelectorSheet extends StatefulWidget {
  final ProductModel product;
  final Function(int quantity) onConfirm;
  final String confirmText;

  const QuantitySelectorSheet({
    super.key,
    required this.product,
    required this.onConfirm,
    this.confirmText = 'Confirm',
  });

  static Future<void> show(
    BuildContext context, {
    required ProductModel product,
    required Function(int) onConfirm,
    String confirmText = 'Confirm',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuantitySelectorSheet(
        product: product,
        onConfirm: onConfirm,
        confirmText: confirmText,
      ),
    );
  }

  @override
  State<QuantitySelectorSheet> createState() => _QuantitySelectorSheetState();
}

class _QuantitySelectorSheetState extends State<QuantitySelectorSheet> {
  int _quantity = 1;

  void _increment() {
    if (_quantity < widget.product.stock) {
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${widget.product.stock} items left in stock'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.colors.surfaceGrey,
                  borderRadius: BorderRadius.circular(12),
                  image: widget.product.images.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.product.images.first),
                          fit: BoxFit.contain,
                        )
                      : null,
                ),
                child: widget.product.images.isEmpty
                    ? Icon(Icons.image_not_supported, color: context.colors.textHint)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatPrice(widget.product.price),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Select Quantity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQtyBtn(Icons.remove, _decrement, _quantity > 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '$_quantity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              _buildQtyBtn(Icons.add, _increment, _quantity < widget.product.stock),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: context.colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onConfirm(_quantity);
            },
            child: Text(
              widget.confirmText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, bool enabled) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? context.colors.primary.withValues(alpha: 0.1) : context.colors.surfaceGrey,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enabled ? context.colors.primary.withValues(alpha: 0.3) : context.colors.border,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? context.colors.primary : context.colors.textHint,
        ),
      ),
    );
  }
}
