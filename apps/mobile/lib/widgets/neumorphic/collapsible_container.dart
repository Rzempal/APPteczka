import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'neu_decoration.dart';

/// Neumorphic collapsible container with animated expand/collapse functionality
///
/// Features:
/// - Chevron icon in top-right corner (ChevronDown when expanded, ChevronRight when collapsed)
/// - Animated content transition (AnimatedCrossFade + AnimatedSize)
/// - Haptic feedback on tap
/// - Neumorphic style icon (flat/pressed states)
/// - Optional callback for state changes
class NeuCollapsibleContainer extends StatefulWidget {
  /// Header widget - always visible
  final Widget header;

  /// Content widget - hidden when collapsed
  final Widget child;

  /// Initial expanded state (default: false = collapsed)
  final bool initiallyExpanded;

  /// Callback when expand state changes
  final ValueChanged<bool>? onExpandChange;

  /// Border radius for the container
  final double borderRadius;

  /// Custom decoration (if null, uses NeuDecoration.flat)
  final BoxDecoration? decoration;

  const NeuCollapsibleContainer({
    super.key,
    required this.header,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpandChange,
    this.borderRadius = 16,
    this.decoration,
  });

  @override
  State<NeuCollapsibleContainer> createState() =>
      _NeuCollapsibleContainerState();
}

class _NeuCollapsibleContainerState extends State<NeuCollapsibleContainer>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _iconController;
  late Animation<double> _iconRotation;
  bool _isIconPressed = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Rotate from 0 (chevron-left = collapsed) to 90 degrees (chevron-down = expanded)
    _iconRotation = Tween<double>(
      begin:
          0.0, // 0 degrees = chevron-left (collapsed, pointing towards header)
      end: -0.25, // -90 degrees = chevron-down (expanded)
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeInOut));

    if (_isExpanded) {
      _iconController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    });
    widget.onExpandChange?.call(_isExpanded);
  }

  void _handleIconTapDown(TapDownDetails details) {
    setState(() => _isIconPressed = true);
  }

  void _handleIconTapUp(TapUpDetails details) {
    setState(() => _isIconPressed = false);
  }

  void _handleIconTapCancel() {
    setState(() => _isIconPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerDecoration =
        widget.decoration ??
        NeuDecoration.flat(isDark: isDark, radius: widget.borderRadius);

    return Container(
      decoration: containerDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row with chevron icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header content (flex)
                Expanded(child: widget.header),
                const SizedBox(width: 8),
                // Chevron icon button
                GestureDetector(
                  onTapDown: _handleIconTapDown,
                  onTapUp: _handleIconTapUp,
                  onTapCancel: _handleIconTapCancel,
                  onTap: _toggleExpanded,
                  child: AnimatedContainer(
                    duration: NeuDecoration.tapDuration,
                    padding: const EdgeInsets.all(8),
                    decoration: _isIconPressed
                        ? NeuDecoration.pressedSmall(isDark: isDark, radius: 8)
                        : NeuDecoration.flatSmall(isDark: isDark, radius: 8),
                    child: RotationTransition(
                      turns: _iconRotation,
                      child: Icon(
                        LucideIcons.chevronLeft,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Collapsible content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [const SizedBox(height: 12), widget.child],
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}
