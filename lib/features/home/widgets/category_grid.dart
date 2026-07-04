import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Horizontal scrolling category chip row for the home screen.
/// In production, categories come from Firestore via a provider.
class CategoryChipRow extends StatefulWidget {
  final ValueChanged<int>? onCategorySelected;

  const CategoryChipRow({super.key, this.onCategorySelected});

  @override
  State<CategoryChipRow> createState() => _CategoryChipRowState();
}

class _CategoryChipRowState extends State<CategoryChipRow> {
  int _selected = 0;

  static const List<_CategoryItem> _categories = [
    _CategoryItem(name: 'All', icon: Icons.grid_view_rounded, color: AppColors.primary),
    _CategoryItem(name: 'Pens', icon: Icons.edit_rounded, color: Color(0xFF5C6BC0)),
    _CategoryItem(name: 'Notebooks', icon: Icons.auto_stories_rounded, color: Color(0xFF26A69A)),
    _CategoryItem(name: 'Inks', icon: Icons.water_drop_rounded, color: Color(0xFF7E57C2)),
    _CategoryItem(name: 'Art', icon: Icons.palette_rounded, color: Color(0xFFEF5350)),
    _CategoryItem(name: 'Office', icon: Icons.work_outline_rounded, color: Color(0xFF29B6F6)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHorizontal),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selected == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selected = index);
              if (widget.onCategorySelected != null) {
                widget.onCategorySelected!(index);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? context.colors.primary : context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? context.colors.primary : context.colors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    cat.icon,
                    size: 18,
                    color: isSelected ? Colors.white : cat.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
