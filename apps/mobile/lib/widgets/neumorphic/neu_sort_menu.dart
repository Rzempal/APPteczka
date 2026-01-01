import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'neu_decoration.dart';

/// Item for NeuSortMenu
class NeuSortMenuItem<T> {
  final T value;
  final String label;
  final IconData icon;

  const NeuSortMenuItem({
    required this.value,
    required this.label,
    required this.icon,
  });
}

/// Neumorphic Sort Menu with animated pressed state and overlay dropdown
///
/// Features:
/// - Animated press state on trigger button
/// - Dropdown menu positioned below the button, aligned right
/// - Neumorphic flat style with shadows
/// - Closes on selection or tap outside
class NeuSortMenu<T> extends StatefulWidget {
  final T currentValue;
  final List<NeuSortMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final String? tooltip;
  final double buttonSize;
  final double borderRadius;

  const NeuSortMenu({
    super.key,
    required this.currentValue,
    required this.items,
    required this.onSelected,
    required this.icon,
    this.tooltip,
    this.buttonSize = 40,
    this.borderRadius = 12,
  });

  @override
  State<NeuSortMenu<T>> createState() => _NeuSortMenuState<T>();
}

class _NeuSortMenuState<T> extends State<NeuSortMenu<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isMenuOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _buttonKey = GlobalKey();

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
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isMenuOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isMenuOpen = false);
    }
  }

  void _selectItem(T value) {
    _removeOverlay();
    widget.onSelected(value);
  }

  OverlayEntry _createOverlayEntry() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get button position
    final RenderBox? renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final buttonSize =
        renderBox?.size ?? Size(widget.buttonSize, widget.buttonSize);
    final buttonPosition = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    // Calculate menu width based on longest label
    const menuWidth = 240.0;
    const menuPadding = 8.0;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap barrier to close menu
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu positioned below button, aligned right
          Positioned(
            top: buttonPosition.dy + buttonSize.height + 8,
            right:
                MediaQuery.of(context).size.width -
                buttonPosition.dx -
                buttonSize.width,
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: menuWidth,
                decoration: NeuDecoration.flat(
                  isDark: isDark,
                  radius: widget.borderRadius,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.items
                        .map(
                          (item) =>
                              _buildMenuItem(item, theme, isDark, menuPadding),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    NeuSortMenuItem<T> item,
    ThemeData theme,
    bool isDark,
    double padding,
  ) {
    final isSelected = item.value == widget.currentValue;

    return InkWell(
      onTap: () => _selectItem(item.value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padding + 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected
                  ? AppColors.primary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine decoration based on state
    BoxDecoration decoration;
    if (_isMenuOpen || _isPressed) {
      decoration = NeuDecoration.pressedSmall(
        isDark: isDark,
        radius: widget.borderRadius,
      );
    } else {
      decoration = NeuDecoration.flatSmall(
        isDark: isDark,
        radius: widget.borderRadius,
      );
    }

    final iconColor = _isMenuOpen
        ? AppColors.primary
        : theme.colorScheme.onSurface.withOpacity(0.8);

    Widget button = CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _buttonKey,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _toggleMenu,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: AnimatedContainer(
            duration: NeuDecoration.tapDuration,
            curve: Curves.easeInOut,
            width: widget.buttonSize,
            height: widget.buttonSize,
            decoration: decoration,
            child: Center(child: Icon(widget.icon, size: 20, color: iconColor)),
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
