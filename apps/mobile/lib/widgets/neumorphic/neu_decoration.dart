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
  // Simulates inner shadow with gradient + asymmetric border
  // Used for: input fields, nested containers inside flat parents
  // ============================================
  static BoxDecoration basin({required bool isDark, double radius = 12}) {
    // Kolory dla efektu wklęsłego:
    // - Górny-lewy róg: ciemny (cień)
    // - Dolny-prawy róg: jasny (highlight)

    if (isDark) {
      // DARK MODE: delikatniejszy efekt
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1f1c), // ciemny cień
            AppColors.darkSurface, // środek
            const Color(0xFF2a3530), // jasny highlight
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
        // Asymetryczny border symulujący inset shadow
        border: Border(
          top: BorderSide(color: Colors.black.withAlpha(80), width: 1.5),
          left: BorderSide(color: Colors.black.withAlpha(80), width: 1.5),
          bottom: BorderSide(color: Colors.white.withAlpha(15), width: 1),
          right: BorderSide(color: Colors.white.withAlpha(15), width: 1),
        ),
      );
    } else {
      // LIGHT MODE: wyraźniejszy efekt
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFd8dcd6), // ciemny cień (góra-lewo)
            const Color(0xFFe8ece8), // środek
            const Color(0xFFF5F7F5), // jasny highlight (dół-prawo)
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
        // Asymetryczny border symulujący inset shadow
        border: Border(
          top: BorderSide(
            color: const Color(0xFFb8bcb8), // ciemny border góra
            width: 1.5,
          ),
          left: BorderSide(
            color: const Color(0xFFb8bcb8), // ciemny border lewo
            width: 1.5,
          ),
          bottom: BorderSide(
            color: Colors.white.withAlpha(200), // jasny border dół
            width: 1,
          ),
          right: BorderSide(
            color: Colors.white.withAlpha(200), // jasny border prawo
            width: 1,
          ),
        ),
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
    Color? borderColor,
  }) {
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    if (isDark) {
      // Dark mode: subtle shadow + optional border
      return BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor.withOpacity(0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      );
    } else {
      // Light mode: full neumorphic shadows
      return BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor.withOpacity(0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: shadowDark.withOpacity(0.2),
            offset: const Offset(shadowDistance, shadowDistance),
            blurRadius: shadowBlur,
          ),
          BoxShadow(
            color: shadowLight.withOpacity(0.7),
            offset: const Offset(-shadowDistanceSm, -shadowDistanceSm),
            blurRadius: shadowBlurSm,
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
