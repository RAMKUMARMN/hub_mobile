// lib/widgets/glass/glass_card.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool hasBorder;
  final double blur;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.hasBorder = true,
    this.blur = 10,
    this.opacity = 0.15,  // Changed from 0.08 to 0.15 (more opaque)
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark 
        ? Colors.white.withValues(alpha: opacity)
        : Colors.white.withValues(alpha: opacity + 0.02);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: glassColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: hasBorder
              ? Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Padding(
              padding: const EdgeInsets.all(2.0), // ADD THIS - prevents text clipping
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}