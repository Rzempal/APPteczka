// neu_basin_container.dart v0.002 Fix: withOpacity -> withValues, usunięto unused bgColor
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// NeuBasinContainer - kontener z prawdziwym efektem wklęsłości (inset shadow)
///
/// W przeciwieństwie do NeuDecoration.basin() który używa tylko gradientu,
/// ten widget symuluje inset box-shadow za pomocą warstw:
/// 1. Zewnętrzny kontener z gradientem tła
/// 2. Górna krawędź z ciemnym cieniem (symulacja inset shadow top-left)
/// 3. Dolna krawędź z jasnym odbiciem (symulacja inset shadow bottom-right)
///
/// Odpowiednik CSS:
/// ```css
/// box-shadow:
///   inset 4px 4px 8px var(--shadow-dark),
///   inset -4px -4px 8px var(--shadow-light);
/// ```
class NeuBasinContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double depth;

  const NeuBasinContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.padding,
    this.depth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors matching CSS .neu-concave gradient
    // CSS: linear-gradient(145deg, var(--color-bg-dark), var(--color-bg-light))
    final bgDark = isDark
        ? AppColors.darkSurfaceLight
        : AppColors.lightSurfaceDark;
    final bgLight = isDark ? AppColors.darkBackground : AppColors.lightSurface;
    // Note: In CSS it is bg-dark top-left to bg-light bottom-right for concave?
    // CSS .neu-concave: bg-dark (top-left) -> bg-light (bottom-right) YES.

    // Shadow colors
    final shadowDark = isDark
        ? AppColors.darkShadowDark.withValues(alpha: 0.8 * depth)
        : AppColors.lightShadowDark.withValues(alpha: 0.5 * depth);

    final shadowLight = isDark
        ? AppColors.darkShadowLight.withValues(alpha: 0.3 * depth)
        : AppColors.lightShadowLight.withValues(alpha: 0.9 * depth);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? const Color(0xFF0b1120)
                : const Color(0xFFd1ddd7), // bg-dark
            isDark
                ? const Color(0xFF1e293b)
                : const Color(0xFFedf3ef), // bg-light
          ],
        ),
        boxShadow: [
          // Outer subtle shadows to ground it
          BoxShadow(
            color: shadowLight.withValues(alpha: 0.1),
            offset: const Offset(1, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Main Content
            Padding(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
            // Inner Shadow Simulation (Top-Left Dark)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        shadowDark.withValues(alpha: isDark ? 0.6 : 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
              ),
            ),
            // Inner Highlight Simulation (Bottom-Right Light)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.bottomRight,
                      end: Alignment.center,
                      colors: [
                        shadowLight.withValues(alpha: isDark ? 0.1 : 0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
