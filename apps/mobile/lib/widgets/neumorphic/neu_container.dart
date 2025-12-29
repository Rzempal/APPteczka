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
class NeuContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool forcePressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final bool enableHaptic;
  final bool isSmall;

  const NeuContainer({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.forcePressed = false,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.width,
    this.height,
    this.enableHaptic = true,
    this.isSmall = false,
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
                  radius: widget.borderRadius,
                )
              : NeuDecoration.flatSmall(
                  isDark: isDark,
                  radius: widget.borderRadius,
                  backgroundColor: widget.backgroundColor,
                ))
        : (showPressed
              ? NeuDecoration.pressed(
                  isDark: isDark,
                  radius: widget.borderRadius,
                )
              : NeuDecoration.flat(
                  isDark: isDark,
                  radius: widget.borderRadius,
                  backgroundColor: widget.backgroundColor,
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
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final bool isPressed;
  final bool isSmall;

  const NeuStaticContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.width,
    this.height,
    this.isPressed = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final decoration = isSmall
        ? (isPressed
              ? NeuDecoration.pressedSmall(isDark: isDark, radius: borderRadius)
              : NeuDecoration.flatSmall(
                  isDark: isDark,
                  radius: borderRadius,
                  backgroundColor: backgroundColor,
                ))
        : (isPressed
              ? NeuDecoration.pressed(isDark: isDark, radius: borderRadius)
              : NeuDecoration.flat(
                  isDark: isDark,
                  radius: borderRadius,
                  backgroundColor: backgroundColor,
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
