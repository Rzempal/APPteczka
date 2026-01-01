import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Model dla elementu nawigacji
class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

/// Floating Navigation Bar z animacjami i efektem neumorficznym
///
/// Główne cechy:
/// - Efekt "lewitowania" (marginesy, cień, zaokrąglone rogi)
/// - Animowane przejścia między stanami (kolor, rozmiar, tekst)
/// - Kolor akcentu: miętowy (AppColors.primary)
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

    // Kolory
    final backgroundColor = isDark ? AppColors.darkSurface : Colors.white;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.darkTextMuted
        : Colors.grey.shade500;
    final activeBgColor = activeColor.withValues(alpha: 0.15);

    return Container(
      // Marginesy - efekt "floating"
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 70,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Cień dolny (ciemny)
          BoxShadow(
            color: isDark
                ? AppColors.darkShadowDark.withValues(alpha: 0.5)
                : AppColors.lightShadowDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          // Cień górny (jasny) - efekt neumorficzny
          BoxShadow(
            color: isDark
                ? AppColors.darkShadowLight.withValues(alpha: 0.1)
                : AppColors.lightShadowLight.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(0, -2),
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
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            activeBgColor: activeBgColor,
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

/// Pojedynczy element nawigacji z animacjami
class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBgColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikona z animowanym kolorem
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                item.icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            // Tekst - animowane pojawienie się
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
