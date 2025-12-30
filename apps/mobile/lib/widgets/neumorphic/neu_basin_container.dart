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

    // Kolory cieni - dostosowane do motywu
    final shadowDark = isDark
        ? AppColors.darkShadowDark.withValues(alpha: 0.8 * depth)
        : AppColors.lightShadowDark.withValues(alpha: 0.5 * depth);

    final shadowLight = isDark
        ? AppColors.darkShadowLight.withValues(alpha: 0.3 * depth)
        : AppColors.lightShadowLight.withValues(alpha: 0.9 * depth);

    // Odległość cienia (proporcjonalna do depth)
    final shadowDistance = 4.0 * depth;
    final blurRadius = 8.0 * depth;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Gradient symulujący wklęsłość - ciemniejszy góra-lewo
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0a0f1a), // bardzo ciemny (góra-lewo)
                  const Color(0xFF131b2e), // środek
                  const Color(0xFF1a2540), // jaśniejszy (dół-prawo)
                ]
              : [
                  const Color(0xFFc8d4cc), // ciemniejszy (góra-lewo)
                  const Color(0xFFdae4de), // środek
                  const Color(0xFFe8f0ea), // jaśniejszy (dół-prawo)
                ],
          stops: const [0.0, 0.4, 1.0],
        ),
        // Zewnętrzne cienie symulujące "wciśnięcie" w powierzchnię
        boxShadow: [
          // Cień wewnętrzny góra-lewo (ciemny) - symulowany przez odwrócone cienie zewnętrzne
          BoxShadow(
            color: shadowDark,
            offset: Offset(shadowDistance, shadowDistance),
            blurRadius: blurRadius,
          ),
          // Odbicie wewnętrzne dół-prawo (jasny)
          BoxShadow(
            color: shadowLight,
            offset: Offset(-shadowDistance * 0.5, -shadowDistance * 0.5),
            blurRadius: blurRadius * 0.5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Warstwa główna z paddingiem
            Padding(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
            // Warstwa górna - symulacja cienia inset (góra-lewo)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        shadowDark.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
            // Warstwa dolna - symulacja odbicia (dół-prawo)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.bottomRight,
                      end: Alignment.center,
                      colors: [
                        shadowLight.withValues(alpha: isDark ? 0.15 : 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
              ),
            ),
            // Górna krawędź - subtelna linia cienia
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        shadowDark.withValues(alpha: 0.6),
                        shadowDark.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Lewa krawędź - subtelna linia cienia
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      bottomLeft: Radius.circular(borderRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        shadowDark.withValues(alpha: 0.6),
                        shadowDark.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Dolna krawędź - highlight
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(borderRadius),
                      bottomRight: Radius.circular(borderRadius),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        shadowLight.withValues(alpha: isDark ? 0.15 : 0.5),
                        shadowLight.withValues(alpha: isDark ? 0.2 : 0.6),
                      ],
                      stops: const [0.0, 0.7, 1.0],
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
