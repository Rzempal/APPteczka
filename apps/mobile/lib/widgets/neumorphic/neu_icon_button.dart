import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'neu_decoration.dart';

/// Neumorphic icon button for toolbars and actions
///
/// Features:
/// - Compact size (40x40 default)
/// - Active state with primary color
/// - Tooltip support
/// - Animated press state
/// Mode for NeuIconButton display
enum NeuIconButtonMode {
  /// Standard look with background and shadow
  visible,

  /// Minimal look, only icon is visible (no background/shadow)
  /// Background appears only when pressed or active
  iconOnly,
}

class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isActive;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? activeColor;
  final Color? iconColor;
  final NeuIconButtonMode mode;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isActive = false,
    this.size = 40,
    this.iconSize = 20,
    this.borderRadius = 12,
    this.activeColor,
    this.iconColor,
    this.mode = NeuIconButtonMode.visible,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: NeuDecoration.iconTapScale,
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
      HapticFeedback.selectionClick();
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
    final activeColor = widget.activeColor ?? AppColors.primary;

    // Determine decoration
    BoxDecoration? decoration;
    if (widget.isActive || _isPressed) {
      decoration = NeuDecoration.pressedSmall(
        isDark: isDark,
        radius: widget.borderRadius,
      );
    } else if (widget.mode == NeuIconButtonMode.visible) {
      decoration = NeuDecoration.flatSmall(
        isDark: isDark,
        radius: widget.borderRadius,
      );
    } else {
      // iconOnly mode and not pressed/active -> transparent
      decoration = null;
    }

    // Icon color
    final iconColor =
        widget.iconColor ??
        (widget.isActive
            ? activeColor
            : theme.colorScheme.onSurface.withValues(alpha: 0.8));

    Widget button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: NeuDecoration.tapDuration,
          curve: Curves.easeInOut,
          width: widget.size,
          height: widget.size,
          decoration: decoration,
          child: Center(
            child: Icon(widget.icon, size: widget.iconSize, color: iconColor),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

/// Badge wrapper for NeuIconButton
/// Shows a count badge on top-right corner
class NeuIconButtonBadge extends StatelessWidget {
  final NeuIconButton button;
  final int count;
  final bool showBadge;

  const NeuIconButtonBadge({
    super.key,
    required this.button,
    required this.count,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge || count == 0) {
      return button;
    }

    return Badge(
      label: Text(
        count.toString(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primary,
      child: button,
    );
  }
}
