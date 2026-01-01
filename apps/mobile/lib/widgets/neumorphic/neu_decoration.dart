import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Neumorphic Decoration System
/// Inspired by Android neumorphism library (fornewid/neumorphism)
///
/// ShapeTypes:
/// - flat: raised element with outer shadows (default buttons, cards)
/// - pressed: sunken element (active/clicked state)
/// - basin: deeply concave (input fields)
class NeuDecoration {
  // ============================================
  // SHADOW CONSTANTS
  // Aligned with neumorph_shadowElevation from Android lib
  // ============================================
  static const double shadowDistance = 6.0;
  static const double shadowBlur = 12.0;
  static const double shadowDistanceSm = 4.0;
  static const double shadowBlurSm = 8.0;
  static const double shadowDistanceXs = 2.0;
  static const double shadowBlurXs = 4.0;

  // ============================================
  // ANIMATION CONSTANTS
  // ============================================
  static const Duration tapDuration = Duration(milliseconds: 100);
  static const double tapScale = 0.98;
  static const double buttonTapScale = 0.95;
  static const double iconTapScale = 0.90;

  // ============================================
  // FLAT - Raised element with outer shadows
  // ============================================
  static BoxDecoration flat({
    required bool isDark,
    double radius = 16,
    Color? backgroundColor,
  }) {
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.lightBackground);
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        // Dark shadow (bottom-right)
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.6 : 0.6),
          offset: const Offset(shadowDistance, shadowDistance),
          blurRadius: shadowBlur,
        ),
        // Light shadow (top-left)
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.1 : 1.0),
          offset: const Offset(-shadowDistance, -shadowDistance),
          blurRadius: shadowBlur,
        ),
      ],
    );
  }

  // ============================================
  // FLAT SMALL - For chips, tags, small buttons
  // ============================================
  static BoxDecoration flatSmall({
    required bool isDark,
    double radius = 12,
    Color? backgroundColor,
  }) {
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.lightBackground);
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.6 : 0.6),
          offset: const Offset(shadowDistanceSm, shadowDistanceSm),
          blurRadius: shadowBlurSm,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.1 : 1.0),
          offset: const Offset(-shadowDistanceSm, -shadowDistanceSm),
          blurRadius: shadowBlurSm,
        ),
      ],
    );
  }

  // ============================================
  // PRESSED - Sunken element (active state)
  // Simulates inset shadow with gradient
  // ============================================
  static BoxDecoration pressed({
    required bool isDark,
    double radius = 16,
    Color? backgroundColor,
  }) {
    // Gradient colors for inset effect
    final darkShade = isDark
        ? AppColors.darkBackground
        : AppColors.lightSurfaceDark;
    final lightShade = isDark
        ? AppColors.darkSurfaceLight.withOpacity(0.5)
        : AppColors.lightSurface;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkShade, lightShade],
      ),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  // ============================================
  // PRESSED SMALL - For small elements
  // ============================================
  static BoxDecoration pressedSmall({
    required bool isDark,
    double radius = 12,
  }) {
    final darkShade = isDark
        ? AppColors.darkBackground
        : AppColors.lightSurfaceDark;
    final lightShade = isDark
        ? AppColors.darkSurfaceLight.withOpacity(0.5)
        : AppColors.lightSurface;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkShade, lightShade],
      ),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  // ============================================
  // BASIN - Deeply concave (inset effect)
  // Strong inner shadow simulation with gradient
  // Used for: input fields, nested containers inside flat parents
  // ============================================
  static BoxDecoration basin({required bool isDark, double radius = 12}) {
    if (isDark) {
      // DARK MODE - silny efekt wklęsły
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0a0d0c), // bardzo ciemny cień (góra-lewo)
            Color(0xFF151918), // środek
            Color(0xFF1e2422), // jasny highlight (dół-prawo)
          ],
          stops: [0.0, 0.35, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
      );
    } else {
      // LIGHT MODE - silny efekt wklęsły (jak w sekcji filtrów web)
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFb8beb6), // ciemny cień (góra-lewo) - silniejszy
            Color(0xFFcdd3c9), // środek
            Color(0xFFe0e6dc), // jasny highlight (dół-prawo)
          ],
          stops: [0.0, 0.35, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
      );
    }
  }

  // ============================================
  // CONVEX - Raised with gradient highlight
  // ============================================
  static BoxDecoration convex({required bool isDark, double radius = 16}) {
    final lightShade = isDark
        ? AppColors.darkSurfaceLight
        : AppColors.lightSurface;
    final darkShade = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurfaceDark;
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightShade, darkShade],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark.withOpacity(isDark ? 0.5 : 0.25),
          offset: const Offset(shadowDistance, shadowDistance),
          blurRadius: shadowBlur,
        ),
        BoxShadow(
          color: shadowLight.withOpacity(isDark ? 0.05 : 0.8),
          offset: const Offset(-shadowDistance, -shadowDistance),
          blurRadius: shadowBlur,
        ),
      ],
    );
  }

  // ============================================
  // STATUS CARD - Medicine cards with status gradient
  // ============================================
  static BoxDecoration statusCard({
    required bool isDark,
    required LinearGradient gradient,
    double radius = 16,
    Color? paramsBorderColor, // kept for compatibility
  }) {
    // Light mode: clean neumorphism
    if (!isDark) {
      return BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightShadowDark.withValues(alpha: 0.25),
            offset: const Offset(shadowDistance, shadowDistance),
            blurRadius: shadowBlur,
          ),
          BoxShadow(
            color: AppColors.lightShadowLight.withValues(alpha: 0.8),
            offset: const Offset(-shadowDistanceSm, -shadowDistanceSm),
            blurRadius: shadowBlurSm,
          ),
        ],
      );
    }

    // Dark Mode: Glass Effect (Web match)
    // CSS: border: 1px solid rgba(148, 163, 184, 0.1);
    // CSS: box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);

    // Determine status type for border color (heuristic based on gradient)
    Color baseColor = gradient.colors.first;
    Color borderColor = const Color(
      0xFF94a3b8,
    ).withValues(alpha: 0.1); // default
    Color glowColor = Colors.transparent;

    // Check for "Valid" (Green)
    if (baseColor.value == 0xFF064e3b || baseColor == AppColors.valid) {
      borderColor = const Color(0xFF10b981).withValues(alpha: 0.3);
      glowColor = const Color(0xFF10b981).withValues(alpha: 0.1);
    }
    // Check for "Warning/Expiring" (Amber/Orange)
    else if (baseColor.value == 0xFF78350f ||
        baseColor == AppColors.expiringSoon) {
      borderColor = const Color(0xFFf59e0b).withValues(alpha: 0.3);
      glowColor = const Color(0xFFf59e0b).withValues(alpha: 0.1);
    }
    // Check for "Expired" (Red)
    else if (baseColor.value == 0xFF7f1d1d || baseColor == AppColors.expired) {
      borderColor = const Color(0xFFef4444).withValues(alpha: 0.3);
      glowColor = const Color(0xFFef4444).withValues(alpha: 0.1);
    }

    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          offset: const Offset(0, 8),
          blurRadius: 32,
        ),
        if (glowColor != Colors.transparent)
          BoxShadow(
            color: glowColor,
            offset: const Offset(0, 0),
            blurRadius: 12,
          ),
      ],
    );
  }

  // ============================================
  // PRIMARY BUTTON - Green accent
  // ============================================
  static BoxDecoration primaryButton({
    required bool isDark,
    double radius = 12,
    bool isPressed = false,
  }) {
    if (isPressed) {
      return BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(radius),
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryLight, AppColors.primary],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.4),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ],
    );
  }

  // ============================================
  // DESTRUCTIVE BUTTON - Red accent
  // ============================================
  static BoxDecoration destructiveButton({
    required bool isDark,
    double radius = 12,
    bool isPressed = false,
  }) {
    if (isPressed) {
      return BoxDecoration(
        color: const Color(0xFFb91c1c), // red-700
        borderRadius: BorderRadius.circular(radius),
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFf87171), AppColors.expired], // red-400 to red-500
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.expired.withOpacity(0.4),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ],
    );
  }
}
