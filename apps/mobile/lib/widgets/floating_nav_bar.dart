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
/// - Organic shape: asymetryczne zaokrąglenia (Soft UI 2026)
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> items;
  final bool performanceMode;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.performanceMode = false,
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        // Swipe gesture - przełączanie zakładek
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 100) return; // Ignoruj małe ruchy

        int newIndex;
        if (velocity < 0) {
          // Swipe left → zakładka w lewo (poprzednia)
          newIndex = (currentIndex - 1 + items.length) % items.length;
        } else {
          // Swipe right → zakładka w prawo (następna)
          newIndex = (currentIndex + 1) % items.length;
        }

        HapticFeedback.lightImpact();
        onTap(newIndex);
      },
      child: Container(
        // Marginesy - efekt "floating"
        margin: const EdgeInsets.all(16),
        height: 72,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppTheme.organicRadiusSmall, // Organic shape (Soft UI 2026)
          // Cienie neumorficzne - flat style (Small variant: ±6, blur 12)
          boxShadow: [
            // Cień jasny (top-left)
            BoxShadow(
              color: shadowLight.withValues(alpha: isDark ? 0.1 : 1.0),
              blurRadius: performanceMode ? 6.0 : 12.0,
              offset: Offset(
                performanceMode ? -3.0 : -6.0,
                performanceMode ? -3.0 : -6.0,
              ),
            ),
            // Cień ciemny (bottom-right)
            BoxShadow(
              color: shadowDark.withValues(alpha: isDark ? 0.6 : 0.6),
              blurRadius: performanceMode ? 6.0 : 12.0,
              offset: Offset(
                performanceMode ? 3.0 : 6.0,
                performanceMode ? 3.0 : 6.0,
              ),
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
              performanceMode: performanceMode,
              onTap: () {
                HapticFeedback.lightImpact();
                onTap(index);
              },
            );
          }).toList(),
        ),
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
  final bool performanceMode;
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
    required this.performanceMode,
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
                shape: BoxShape.circle,
                // Gradient zawsze obecny - płynna interpolacja bez artefaktów
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? (isDark
                          ? [
                              AppColors.darkShadowLight,
                              AppColors.darkSurface,
                            ]
                          : [
                              AppColors.lightSurface,
                              AppColors.lightShadowDark,
                            ])
                      : [backgroundColor, backgroundColor],
                ),
                // Cienie neumorficzne - tylko dla aktywnego (convex)
                // XS variant dla małego elementu
                boxShadow: isSelected
                    ? [
                        // Jasny cień (top-left) - efekt wypukłości
                        BoxShadow(
                          color: shadowLight.withValues(
                            alpha: isDark ? 0.1 : 1.0,
                          ),
                          blurRadius: performanceMode ? 3.0 : 6.0,
                          offset: Offset(
                            performanceMode ? -1.5 : -3.0,
                            performanceMode ? -1.5 : -3.0,
                          ),
                        ),
                        // Ciemny cień (bottom-right)
                        BoxShadow(
                          color: shadowDark.withValues(
                            alpha: isDark ? 0.6 : 0.5,
                          ),
                          blurRadius: performanceMode ? 3.0 : 6.0,
                          offset: Offset(
                            performanceMode ? 1.5 : 3.0,
                            performanceMode ? 1.5 : 3.0,
                          ),
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
