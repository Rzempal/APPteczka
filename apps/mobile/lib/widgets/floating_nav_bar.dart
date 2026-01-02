import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Model dla elementu nawigacji
class NavItem {
  final IconData icon;
  final Widget Function(Color color, double size)? iconBuilder;
  final String label;

  const NavItem({required this.icon, required this.label, this.iconBuilder});
}

/// Floating Navigation Bar z efektem neumorficznym
///
/// Główne cechy:
/// - Tło: kolory neumorficzne (nie białe)
/// - Aktywny element: efekt convex (wypukły, "wypływa" nad pasek)
/// - Cienie neumorficzne (light top-left, dark bottom-right)
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Kolory neumorficzne - takie same jak w reszcie aplikacji
    final backgroundColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Container(
      // Marginesy - efekt "floating"
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 72,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        // Cienie neumorficzne - flat style
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
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = currentIndex == index;

          return _NavBarItem(
            item: item,
            isSelected: isSelected,
            isDark: isDark,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            backgroundColor: backgroundColor,
            shadowLight: shadowLight,
            shadowDark: shadowDark,
            onTap: () {
              HapticFeedback.lightImpact();
              onTap(index);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Pojedynczy element nawigacji z efektem convex dla aktywnego
class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool isDark;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final Color shadowLight;
  final Color shadowDark;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
    required this.shadowLight,
    required this.shadowDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animowany kontener z efektem convex
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 56 : 44,
              height: isSelected ? 56 : 44,
              // Efekt "wypływania" - ujemny margin gdy aktywny
              transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                // Gradient convex dla aktywnego elementu
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.darkSurfaceLight,
                                AppColors.darkSurface,
                              ]
                            : [
                                AppColors.lightSurface,
                                AppColors.lightSurfaceDark,
                              ],
                      )
                    : null,
                // Cienie neumorficzne - tylko dla aktywnego (convex)
                boxShadow: isSelected
                    ? [
                        // Jasny cień (top-left) - efekt wypukłości
                        BoxShadow(
                          color: shadowLight,
                          blurRadius: 8,
                          offset: const Offset(-3, -3),
                        ),
                        // Ciemny cień (bottom-right)
                        BoxShadow(
                          color: shadowDark.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(3, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: item.iconBuilder != null
                    ? item.iconBuilder!(
                        isSelected ? activeColor : inactiveColor,
                        isSelected ? 32 : 28,
                      )
                    : Icon(
                        item.icon,
                        color: isSelected ? activeColor : inactiveColor,
                        size: isSelected ? 32 : 28,
                      ),
              ),
            ),
            // Etykieta tekstowa - tylko dla NIEAKTYWNYCH
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 0.0 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isSelected ? 0 : 16,
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: inactiveColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
