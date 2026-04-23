import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Stronger aeroglass effect
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.2), // More transparent for better glass effect
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), // Subtle white border for specular highlight
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
