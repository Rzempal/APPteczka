import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'neu_decoration.dart';

/// Animated neumorphic container with tap support
///
/// Provides:
/// - Automatic theme detection (light/dark)
/// - Animated transition between flat and pressed states
/// - Optional onTap callback with haptic feedback
/// - Scale animation on press
/// - Support for organic border radius (Soft UI 2026)
class NeuContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool forcePressed;
  final BorderRadius? borderRadius; // Organic radius support
  final double radius; // Fallback to circular
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final bool enableHaptic;
  final bool isSmall;
  final bool performanceMode; // Performance toggle

  const NeuContainer({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.forcePressed = false,
    this.borderRadius, // Optional organic radius
    this.radius = 16, // Default circular radius
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.width,
    this.height,
    this.enableHaptic = true,
    this.isSmall = false,
    this.performanceMode = false,
  });

  @override
  State<NeuContainer> createState() => _NeuContainerState();
}

class _NeuContainerState extends State<NeuContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: NeuDecoration.tapDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.isSmall ? NeuDecoration.iconTapScale : NeuDecoration.tapScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
      _controller.forward();
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showPressed = _isPressed || widget.forcePressed;

    final decoration = widget.isSmall
        ? (showPressed
              ? NeuDecoration.pressedSmall(
                  isDark: isDark,
                  borderRadius: widget.borderRadius,
                  radius: widget.radius,
                  backgroundColor: widget.backgroundColor,
                )
              : NeuDecoration.flatSmall(
                  isDark: isDark,
                  borderRadius: widget.borderRadius,
                  radius: widget.radius,
                  backgroundColor: widget.backgroundColor,
                  performanceMode: widget.performanceMode,
                ))
        : (showPressed
              ? NeuDecoration.pressed(
                  isDark: isDark,
                  borderRadius: widget.borderRadius,
                  radius: widget.radius,
                  backgroundColor: widget.backgroundColor,
                )
              : NeuDecoration.flat(
                  isDark: isDark,
                  borderRadius: widget.borderRadius,
                  radius: widget.radius,
                  backgroundColor: widget.backgroundColor,
                  performanceMode: widget.performanceMode,
                ));

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: NeuDecoration.tapDuration,
          curve: Curves.easeInOut,
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: decoration,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Simple non-animated neumorphic container
/// For static elements that don't need interaction
class NeuStaticContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius; // Organic radius support
  final double radius; // Fallback to circular
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final bool isPressed;
  final bool isSmall;
  final bool performanceMode;

  const NeuStaticContainer({
    super.key,
    required this.child,
    this.borderRadius, // Optional organic radius
    this.radius = 16, // Default circular radius
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.width,
    this.height,
    this.isPressed = false,
    this.isSmall = false,
    this.performanceMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final decoration = isSmall
        ? (isPressed
              ? NeuDecoration.pressedSmall(
                  isDark: isDark,
                  borderRadius: borderRadius,
                  radius: radius,
                  backgroundColor: backgroundColor,
                )
              : NeuDecoration.flatSmall(
                  isDark: isDark,
                  borderRadius: borderRadius,
                  radius: radius,
                  backgroundColor: backgroundColor,
                  performanceMode: performanceMode,
                ))
        : (isPressed
              ? NeuDecoration.pressed(
                  isDark: isDark,
                  borderRadius: borderRadius,
                  radius: radius,
                  backgroundColor: backgroundColor,
                )
              : NeuDecoration.flat(
                  isDark: isDark,
                  borderRadius: borderRadius,
                  radius: radius,
                  backgroundColor: backgroundColor,
                  performanceMode: performanceMode,
                ));

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}
