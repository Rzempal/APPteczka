import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Neumorphic container with true INNER shadows (debossed/inset effect)
///
/// Uses Stack with gradient overlays to simulate CSS `inset box-shadow`
/// because Flutter's BoxShadow doesn't support inset shadows.
///
/// The shadow gradients are positioned INSIDE the container at the edges,
/// creating the illusion of a sunken/pressed surface.
class NeuInsetContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;

  /// Depth of the inner shadow (how far the gradient extends)
  final double shadowDepth;

  /// Opacity of the shadow (0.0 - 1.0)
  final double shadowOpacity;

  const NeuInsetContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.shadowDepth = 8.0,
    this.shadowOpacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final shadowColor = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;
    final highlightColor = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;

    // Calculate stop position for gradient (relative to container size)
    // Using a fixed stop that works well for most sizes
    const double gradientStop = 0.15;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Content with padding
            Padding(
              padding: padding,
              child: child,
            ),

            // Inner shadow overlays (IgnorePointer so they don't block taps)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _InnerShadowPainter(
                    shadowColor: shadowColor,
                    highlightColor: highlightColor,
                    shadowOpacity: isDark ? shadowOpacity * 0.8 : shadowOpacity,
                    highlightOpacity: isDark ? 0.1 : shadowOpacity * 0.6,
                    shadowDepth: shadowDepth,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for inner shadows
/// Draws gradient shadows on the inner edges of the container
class _InnerShadowPainter extends CustomPainter {
  final Color shadowColor;
  final Color highlightColor;
  final double shadowOpacity;
  final double highlightOpacity;
  final double shadowDepth;
  final double borderRadius;

  _InnerShadowPainter({
    required this.shadowColor,
    required this.highlightColor,
    required this.shadowOpacity,
    required this.highlightOpacity,
    required this.shadowDepth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Top shadow (dark)
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        shadowColor.withValues(alpha: shadowOpacity),
        shadowColor.withValues(alpha: 0),
      ],
    );

    final topRect = Rect.fromLTWH(0, 0, size.width, shadowDepth);
    final topPaint = Paint()
      ..shader = topGradient.createShader(topRect);
    canvas.drawRect(topRect, topPaint);

    // Left shadow (dark)
    final leftGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        shadowColor.withValues(alpha: shadowOpacity * 0.7),
        shadowColor.withValues(alpha: 0),
      ],
    );

    final leftRect = Rect.fromLTWH(0, 0, shadowDepth, size.height);
    final leftPaint = Paint()
      ..shader = leftGradient.createShader(leftRect);
    canvas.drawRect(leftRect, leftPaint);

    // Bottom highlight (light)
    final bottomGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        highlightColor.withValues(alpha: highlightOpacity),
        highlightColor.withValues(alpha: 0),
      ],
    );

    final bottomRect = Rect.fromLTWH(
      0,
      size.height - shadowDepth,
      size.width,
      shadowDepth,
    );
    final bottomPaint = Paint()
      ..shader = bottomGradient.createShader(bottomRect);
    canvas.drawRect(bottomRect, bottomPaint);

    // Right highlight (light)
    final rightGradient = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        highlightColor.withValues(alpha: highlightOpacity * 0.7),
        highlightColor.withValues(alpha: 0),
      ],
    );

    final rightRect = Rect.fromLTWH(
      size.width - shadowDepth,
      0,
      shadowDepth,
      size.height,
    );
    final rightPaint = Paint()
      ..shader = rightGradient.createShader(rightRect);
    canvas.drawRect(rightRect, rightPaint);
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) {
    return oldDelegate.shadowColor != shadowColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.shadowOpacity != shadowOpacity ||
        oldDelegate.highlightOpacity != highlightOpacity ||
        oldDelegate.shadowDepth != shadowDepth;
  }
}

/// Smaller variant with less depth - for buttons and small elements
class NeuInsetContainerSmall extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;

  const NeuInsetContainerSmall({
    super.key,
    required this.child,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return NeuInsetContainer(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      shadowDepth: 5.0,
      shadowOpacity: 0.3,
      child: child,
    );
  }
}
