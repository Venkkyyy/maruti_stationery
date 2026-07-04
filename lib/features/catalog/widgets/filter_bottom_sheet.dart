import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';

/// Bottom sheet with sort and filter options for the catalog screen.
class FilterBottomSheet extends StatefulWidget {
  final String? initialSort;
  final RangeValues? initialPriceRange;
  final ValueChanged<FilterOptions>? onApply;

  const FilterBottomSheet({
    super.key,
    this.initialSort,
    this.initialPriceRange,
    this.onApply,
  });

  /// Open the bottom sheet from a context
  static Future<void> show(
    BuildContext context, {
    FilterOptions? current,
    ValueChanged<FilterOptions>? onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialSort: current?.sortBy,
        initialPriceRange: current?.priceRange,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class FilterOptions {
  final String? sortBy;
  final RangeValues? priceRange;

  const FilterOptions({this.sortBy, this.priceRange});
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _sortBy;
  late RangeValues _priceRange;

  static const List<_SortOption> _sortOptions = [
    _SortOption('Newest First', 'newest'),
    _SortOption('Price: Low to High', 'price_asc'),
    _SortOption('Price: High to Low', 'price_desc'),
    _SortOption('Discount', 'discount'),
  ];

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSort;
    _priceRange = widget.initialPriceRange ?? const RangeValues(0, 10000);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortBy = null;
                    _priceRange = const RangeValues(0, 10000);
                  });
                },
                child: Text(
                  'Reset',
                  style: TextStyle(color: context.colors.primary),
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Sort by
          Text(
            'SORT BY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((opt) {
              final selected = _sortBy == opt.value;
              return GestureDetector(
                onTap: () => setState(() => _sortBy = opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? context.colors.primary : context.colors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? context.colors.primary : context.colors.border,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : context.colors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Price range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRICE RANGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '₹${_priceRange.start.toInt()} – ₹${_priceRange.end.toInt()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            activeColor: context.colors.primary,
            inactiveColor: context.colors.border,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: 16),

          // Apply button
          AppButton.primary(
            text: 'Apply Filters',
            onPressed: () {
              widget.onApply?.call(FilterOptions(
                sortBy: _sortBy,
                priceRange: _priceRange,
              ));
              Navigator.pop(context);
            },
            height: 50,
          ),
        ],
      ),
    );
  }
}

class _SortOption {
  final String label;
  final String value;
  const _SortOption(this.label, this.value);
}






