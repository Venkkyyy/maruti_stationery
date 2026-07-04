import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../../models/order_model.dart';

/// Vertical tracking stepper showing order progress.
class OrderStatusStepper extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderStatusStepper({super.key, required this.currentStatus});

  static const List<_StepInfo> _steps = [
    _StepInfo(OrderStatus.placed, 'Order Placed', 'We received your order'),
    _StepInfo(OrderStatus.confirmed, 'Confirmed', 'Confirmed by Maruti Stationery'),
    _StepInfo(OrderStatus.packed, 'Packed', 'Items packed and ready'),
    _StepInfo(OrderStatus.shipped, 'Shipped', 'Handed over to courier'),
    _StepInfo(OrderStatus.delivered, 'Delivered', 'Package delivered successfully'),
  ];

  bool _isCompleted(OrderStatus step) {
    // cancelled is a separate terminal state — treat as stuck at placed
    if (currentStatus == OrderStatus.cancelled) {
      return step == OrderStatus.placed;
    }
    return step.index <= currentStatus.index;
  }

  bool _isActive(OrderStatus step) => step == currentStatus;

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.cancelled) {
      return _CancelledBanner();
    }

    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final completed = _isCompleted(step.status);
        final active = _isActive(step.status);
        final isLast = i == _steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: indicator + connector
            Column(
              children: [
                _StepIndicator(isCompleted: completed, isActive: active),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: completed ? context.colors.primary : context.colors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Right side: label + description
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            completed ? FontWeight.w700 : FontWeight.w500,
                        color: completed
                            ? context.colors.textPrimary
                            : context.colors.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: completed
                            ? context.colors.textSecondary
                            : context.colors.textHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StepInfo {
  final OrderStatus status;
  final String label;
  final String description;

  const _StepInfo(this.status, this.label, this.description);
}

class _StepIndicator extends StatelessWidget {
  final bool isCompleted;
  final bool isActive;

  const _StepIndicator({required this.isCompleted, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: context.colors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.primary.withValues(alpha: 0.15),
          border: Border.all(color: context.colors.primary, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: context.colors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: context.colors.surfaceGrey,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.border),
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_rounded, color: context.colors.error, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.colors.error,
                  ),
                ),
                Text(
                  'This order was cancelled. Refund (if any) within 5–7 business days.',
                  style: TextStyle(fontSize: 12, color: context.colors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






