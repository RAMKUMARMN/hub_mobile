// lib/widgets/glass/glass_dropdown.dart
import 'package:flutter/material.dart';
import '../../../themes/app_colors.dart';

class GlassDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String hint;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.width = double.infinity,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: secondaryText),
          ),
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.aiCyan),
          dropdownColor: isDark ? AppColors.surface : Colors.white,
          style: TextStyle(color: textColor, fontSize: 14),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class GlassDropdownButton extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String) onChanged;
  final String hint;
  final double width;

  const GlassDropdownButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.aiCyan),
          dropdownColor: isDark ? AppColors.surface : Colors.white,
          style: TextStyle(color: textColor, fontSize: 14),
        ),
      ),
    );
  }
}