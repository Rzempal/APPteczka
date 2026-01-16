import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'neumorphic/neu_decoration.dart';

/// Toolbar dla widoku Apteczka - wyświetlany nad FloatingNavBar
///
/// Zawiera przyciski: search, sort, filter, clear-filter, menu
class ApteczkaToolbar extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onSort;
  final VoidCallback onFilter;
  final VoidCallback? onClearFilter;
  final VoidCallback onMenu;
  final bool hasActiveFilters;
  final bool isVisible;

  const ApteczkaToolbar({
    super.key,
    required this.onSearch,
    required this.onSort,
    required this.onFilter,
    this.onClearFilter,
    required this.onMenu,
    this.hasActiveFilters = false,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Kolory neumorficzne - takie same jak FloatingNavBar
    final backgroundColor =
        isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final shadowLight =
        isDark ? AppColors.darkShadowLight : AppColors.lightShadowLight;
    final shadowDark =
        isDark ? AppColors.darkShadowDark : AppColors.lightShadowDark;
    final iconColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // Cień jasny (top-left)
              BoxShadow(
                color: shadowLight,
                blurRadius: 12,
                offset: const Offset(-4, -4),
              ),
              // Cień ciemny (bottom-right)
              BoxShadow(
                color: shadowDark.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Search
              _ToolbarButton(
                icon: LucideIcons.search,
                onTap: onSearch,
                iconColor: iconColor,
                isDark: isDark,
              ),
              // Sort
              _ToolbarButton(
                icon: LucideIcons.arrowUpDown,
                onTap: onSort,
                iconColor: iconColor,
                isDark: isDark,
              ),
              // Filter
              _ToolbarButton(
                icon: LucideIcons.funnel,
                onTap: onFilter,
                iconColor: iconColor,
                isDark: isDark,
              ),
              // Clear filter
              _ToolbarButton(
                icon: LucideIcons.funnelX,
                onTap: hasActiveFilters ? onClearFilter : null,
                iconColor: hasActiveFilters ? AppColors.expired : iconColor.withValues(alpha: 0.3),
                isDark: isDark,
              ),
              // Menu
              _ToolbarButton(
                icon: LucideIcons.menu,
                onTap: onMenu,
                iconColor: iconColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pojedynczy przycisk w toolbarze
class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  final bool isDark;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    required this.iconColor,
    required this.isDark,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap != null
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 44,
        height: 44,
        decoration: _isPressed
            ? NeuDecoration.pressedSmall(isDark: widget.isDark, radius: 22)
            : null,
        child: Center(
          child: Icon(
            widget.icon,
            size: 22,
            color: widget.iconColor,
          ),
        ),
      ),
    );
  }
}
