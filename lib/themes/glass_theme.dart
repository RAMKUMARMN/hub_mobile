// lib/themes/glass_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Glassmorphism styling utilities
class GlassTheme {
  // ============ GLASS CARD STYLES ============
  
  /// Glass card decoration for dark mode
  static BoxDecoration glassCardDark({
    double blur = 10,
    double opacity = 0.15,
    double borderRadius = 24,
    bool hasBorder = true,
  }) {
    return BoxDecoration(
      color: AppColors.glassDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder
          ? Border.all(
              color: AppColors.glassBorder,
              width: 1,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  /// Glass card decoration for light mode
  static BoxDecoration glassCardLight({
    double blur = 10,
    double opacity = 0.08,
    double borderRadius = 24,
    bool hasBorder = true,
  }) {
    return BoxDecoration(
      color: AppColors.glassLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder
          ? Border.all(
              color: AppColors.glassBorderLight,
              width: 1,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  /// Dynamic glass card based on theme
  static BoxDecoration glassCard(BuildContext context, {
    double blur = 10,
    double borderRadius = 24,
    bool hasBorder = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? glassCardDark(blur: blur, borderRadius: borderRadius, hasBorder: hasBorder)
        : glassCardLight(blur: blur, borderRadius: borderRadius, hasBorder: hasBorder);
  }

  // ============ GLASS BUTTON STYLES ============
  
  static ButtonStyle glassButtonStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? AppColors.glassDark : AppColors.glassLight,
      foregroundColor: isDark ? Colors.white : AppColors.lightText,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      side: BorderSide(
        color: isDark ? AppColors.glassBorder : AppColors.glassBorderLight,
        width: 1,
      ),
    );
  }

  // ============ GLASS APP BAR ============
  
  static AppBarTheme glassAppBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBarTheme(
      backgroundColor: isDark ? AppColors.glassDark : AppColors.glassLight,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: isDark ? Colors.white : AppColors.lightText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : AppColors.lightText,
      ),
    );
  }

  // ============ GLASS INPUT DECORATION ============
  
  static InputDecorationTheme glassInputDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.glassDark : AppColors.glassLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? AppColors.glassBorder : AppColors.glassBorderLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.aiCyan, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.white54 : Colors.black45,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ============ REUSABLE GLASS WIDGETS ============

/// A glassmorphism card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool hasBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: GlassTheme.glassCard(
          context,
          borderRadius: borderRadius,
          hasBorder: hasBorder,
        ),
        child: child,
      ),
    );
  }
}

/// A glassmorphism button
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;

  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : AppColors.lightText,
          side: BorderSide(
            color: isDark ? AppColors.glassBorder : AppColors.glassBorderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      );
    }
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: GlassTheme.glassButtonStyle(context),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}

/// A glassmorphism chip
class GlassChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final IconData? leadingIcon;

  const GlassChip({
    super.key,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.aiCyan.withValues(alpha: 0.2)
              : (isDark ? AppColors.glassDark : AppColors.glassLight),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppColors.aiCyan
                : (isDark ? AppColors.glassBorder : AppColors.glassBorderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 16, color: isSelected ? AppColors.aiCyan : null),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.aiCyan : null,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A glassmorphism divider
class GlassDivider extends StatelessWidget {
  final double height;
  final double indent;
  final double endIndent;

  const GlassDivider({
    super.key,
    this.height = 1,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Divider(
      height: height,
      indent: indent,
      endIndent: endIndent,
      color: isDark ? AppColors.glassBorder : AppColors.glassBorderLight,
      thickness: 0.5,
    );
  }
}

/// A glassmorphism app bar
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? (leading ?? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ))
          : leading,
      actions: actions,
      flexibleSpace: Container(
        decoration: GlassTheme.glassCard(
          context,
          borderRadius: 0,
          hasBorder: false,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}