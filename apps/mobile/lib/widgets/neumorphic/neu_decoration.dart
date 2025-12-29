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
          color: shadowDark.withOpacity(isDark ? 0.5 : 0.25),
          offset: const Offset(shadowDistance, shadowDistance),
          blurRadius: shadowBlur,
          spreadRadius: 0,
        ),
        // Light shadow (top-left)
        BoxShadow(
          color: shadowLight.withOpacity(isDark ? 0.05 : 0.8),
          offset: const Offset(-shadowDistance, -shadowDistance),
          blurRadius: shadowBlur,
          spreadRadius: 0,
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
          color: shadowDark.withOpacity(isDark ? 0.4 : 0.2),
          offset: const Offset(shadowDistanceSm, shadowDistanceSm),
          blurRadius: shadowBlurSm,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowLight.withOpacity(isDark ? 0.03 : 0.7),
          offset: const Offset(-shadowDistanceSm, -shadowDistanceSm),
          blurRadius: shadowBlurSm,
          spreadRadius: 0,
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
  // Simulates inner shadow with gradient
  // Used for: input fields, nested containers inside flat parents
  // NOTE: Asymmetric border widths don't work with BorderRadius in Flutter
  // ============================================
  static BoxDecoration basin({required bool isDark, double radius = 12}) {
    if (isDark) {
      // DARK MODE - efekt wklęsły bez border (czyste neumorphism)
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF151918), // ciemniejszy cień (góra-lewo)
            Color(0xFF1e2422), // środek
            Color(0xFF282e2c), // jasny highlight (dół-prawo)
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
      );
    } else {
      // LIGHT MODE - wyraźniejszy efekt wklęsły bez border
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFc8ccc4), // ciemniejszy cień (góra-lewo)
            Color(0xFFd8dcd4), // środek
            Color(0xFFe8ece4), // jasny highlight (dół-prawo)
          ],
          stops: [0.0, 0.4, 1.0],
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
    Color? borderColor, // zachowane dla zgodności wstecznej, ale nieużywane
  }) {
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    if (isDark) {
      // Dark mode: czyste neumorphism bez border - cień daje efekt 3D
      return BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Główny cień (dół-prawo)
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(4, 4),
            blurRadius: 12,
            spreadRadius: -1,
          ),
          // Subtelny highlight (góra-lewo)
          BoxShadow(
            color: Colors.white.withOpacity(0.03),
            offset: const Offset(-2, -2),
            blurRadius: 6,
          ),
        ],
      );
    } else {
      // Light mode: pełne neumorphic shadows bez border
      return BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Ciemny cień (dół-prawo)
          BoxShadow(
            color: shadowDark.withOpacity(0.25),
            offset: const Offset(shadowDistance, shadowDistance),
            blurRadius: shadowBlur,
            spreadRadius: 0,
          ),
          // Jasny cień/highlight (góra-lewo)
          BoxShadow(
            color: shadowLight.withOpacity(0.8),
            offset: const Offset(-shadowDistanceSm, -shadowDistanceSm),
            blurRadius: shadowBlurSm,
            spreadRadius: 0,
          ),
        ],
      );
    }
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
