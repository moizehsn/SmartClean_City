import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A glassmorphic container with backdrop blur and botanical shadow.
/// Used as the primary surface for cards, modals, and floating elements
/// per the Urban Organicism design system.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.opacity = 0.6,
    this.blurSigma = 24.0,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  /// Opacity of the white glass surface (0.0 – 1.0)
  final double opacity;

  /// Backdrop blur intensity
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppColors.botanicalShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              // Ghost Border — barely perceptible, never a hard line
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
