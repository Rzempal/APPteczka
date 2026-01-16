import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';

/// Toolbar dla widoku Apteczka - wyświetlany nad FloatingNavBar
///
/// Styl glassmorphism - lekka przezroczystość z blur.
/// Kolejność przycisków: clear-filter, filter, search, sort, menu
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

    // Glassmorphism - przezroczyste tło z blur
    final backgroundColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.85)
        : AppColors.lightBackground.withValues(alpha: 0.85);
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. Clear filter (funnel-x)
                    _ToolbarButton(
                      icon: LucideIcons.funnelX,
                      onTap: hasActiveFilters ? onClearFilter : null,
                      iconColor: hasActiveFilters
                          ? AppColors.expired
                          : iconColor.withValues(alpha: 0.3),
                      isDark: isDark,
                    ),
                    // 2. Filter (funnel)
                    _ToolbarButton(
                      icon: LucideIcons.funnel,
                      onTap: onFilter,
                      iconColor: iconColor,
                      isDark: isDark,
                    ),
                    // 3. Search
                    _ToolbarButton(
                      icon: LucideIcons.search,
                      onTap: onSearch,
                      iconColor: iconColor,
                      isDark: isDark,
                    ),
                    // 4. Sort
                    _ToolbarButton(
                      icon: LucideIcons.arrowUpDown,
                      onTap: onSort,
                      iconColor: iconColor,
                      isDark: isDark,
                    ),
                    // 5. Menu
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
      onTapDown:
          widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp:
          widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel:
          widget.onTap != null ? () => setState(() => _isPressed = false) : null,
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
            ? BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(22),
              )
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
