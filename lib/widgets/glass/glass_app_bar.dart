// lib/widgets/glass/glass_app_bar.dart
import 'package:flutter/material.dart';
import '../../../themes/app_colors.dart';
import 'dart:ui'; 

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final Color? backgroundColor;
  final double elevation;
  final bool centerTitle;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.backgroundColor,
    this.elevation = 0,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final defaultBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.7);

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: backgroundColor ?? defaultBgColor,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: showBackButton
          ? (leading ?? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => Navigator.pop(context),
            ))
          : leading,
      actions: actions,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class GlassTransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final Color? iconColor;

  const GlassTransparentAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final defaultIconColor = iconColor ?? (isDark ? Colors.white : AppColors.lightText);

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? (leading ?? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: defaultIconColor),
              onPressed: () => Navigator.pop(context),
            ))
          : leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class GlassSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onSearch;
  final VoidCallback? onCancel;
  final VoidCallback? onMicTap;

  const GlassSearchAppBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onSearch,
    this.onCancel,
    this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        height: 45,
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.search, color: secondaryText, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: secondaryText, fontSize: 14),
                  border: InputBorder.none,
                ),
                autofocus: true,
                onSubmitted: (_) => onSearch?.call(),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: secondaryText, size: 18),
                onPressed: () {
                  controller.clear();
                  onCancel?.call();
                },
              ),
            if (onMicTap != null)
              IconButton(
                icon: const Icon(Icons.mic, color: AppColors.aiCyan, size: 20),
                onPressed: onMicTap,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.aiCyan),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}