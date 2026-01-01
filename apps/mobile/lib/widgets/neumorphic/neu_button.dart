import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'neu_decoration.dart';

/// Neumorphic button with label and/or icon
///
/// Variants:
/// - default: neumorphic flat style
/// - primary: green accent gradient
/// - destructive: red accent gradient
class NeuButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Widget? child; // Custom content (overrides label/icon)
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isExpanded;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final double fontSize;

  const NeuButton({
    super.key,
    this.label,
    this.icon,
    this.child,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isExpanded = false,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.iconSize = 20,
    this.fontSize = 15,
  });

  /// Primary button factory
  const NeuButton.primary({
    super.key,
    this.label,
    this.icon,
    this.child,
    this.onPressed,
    this.isExpanded = false,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.iconSize = 20,
    this.fontSize = 15,
  }) : isPrimary = true,
       isDestructive = false;

  /// Destructive button factory
  const NeuButton.destructive({
    super.key,
    this.label,
    this.icon,
    this.child,
    this.onPressed,
    this.isExpanded = false,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.iconSize = 20,
    this.fontSize = 15,
  }) : isPrimary = false,
       isDestructive = true;

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton>
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
      end: NeuDecoration.buttonTapScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticFeedback.lightImpact();
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

  BoxDecoration _getDecoration(bool isDark) {
    if (widget.isPrimary) {
      return NeuDecoration.primaryButton(
        isDark: isDark,
        radius: widget.borderRadius,
        isPressed: _isPressed,
      );
    } else if (widget.isDestructive) {
      return NeuDecoration.destructiveButton(
        isDark: isDark,
        radius: widget.borderRadius,
        isPressed: _isPressed,
      );
    } else {
      return _isPressed
          ? NeuDecoration.pressed(isDark: isDark, radius: widget.borderRadius)
          : NeuDecoration.flat(isDark: isDark, radius: widget.borderRadius);
    }
  }

  Color _getContentColor(ThemeData theme) {
    if (widget.isPrimary || widget.isDestructive) {
      return Colors.white;
    }
    return theme.colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final contentColor = _getContentColor(theme);
    final isDisabled = widget.onPressed == null;

    Widget content =
        widget.child ??
        Row(
          mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: widget.iconSize,
                color: isDisabled
                    ? contentColor.withOpacity(0.5)
                    : contentColor,
              ),
              if (widget.label != null) const SizedBox(width: 8),
            ],
            if (widget.label != null)
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? contentColor.withOpacity(0.5)
                      : contentColor,
                ),
              ),
          ],
        );

    return GestureDetector(
      onTapDown: isDisabled ? null : _handleTapDown,
      onTapUp: isDisabled ? null : _handleTapUp,
      onTapCancel: isDisabled ? null : _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: isDisabled ? 1.0 : _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: NeuDecoration.tapDuration,
          curve: Curves.easeInOut,
          padding: widget.padding,
          decoration: _getDecoration(isDark).copyWith(
            color: isDisabled
                ? (isDark ? Colors.grey[800] : Colors.grey[300])
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}
