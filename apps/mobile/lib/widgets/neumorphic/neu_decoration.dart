import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Neumorphic Decoration System - Soft UI 2026
/// Based on "Premium Soft UI / Neumorphism" specification
///
/// ShapeTypes:
/// - flat (extruded): raised element with outer shadows (default buttons, cards)
/// - pressed (inset): sunken element (active/clicked state)
/// - basin: deeply concave (input fields)
///
/// Performance Mode:
/// - Full: offset ±10, blur 20 (default)
/// - Performance: offset ±4, blur 8 (reduced GPU load)
class NeuDecoration {
  // ============================================
  // SHADOW CONSTANTS - Soft UI 2026 Spec
  // Full mode: extruded effect with deep shadows
  // Performance mode: reduced shadows for older devices
  // ============================================
  // Full mode (default)
  static const double shadowDistance = 10.0; // Spec: Offset(±10, ±10)
  static const double shadowBlur = 20.0; // Spec: blurRadius 16-24
  static const double shadowDistanceSm = 6.0;
  static const double shadowBlurSm = 12.0;
  static const double shadowDistanceXs = 3.0;
  static const double shadowBlurXs = 6.0;

  // Performance mode (reduced GPU load)
  static const double shadowDistancePerf = 4.0;
  static const double shadowBlurPerf = 8.0;
  static const double shadowDistanceSmPerf = 3.0;
  static const double shadowBlurSmPerf = 6.0;

  // ============================================
  // ANIMATION CONSTANTS
  // ============================================
  static const Duration tapDuration = Duration(milliseconds: 100);
  static const double tapScale = 0.98;
  static const double buttonTapScale = 0.95;
  static const double iconTapScale = 0.90;

  // ============================================
  // FLAT - Raised element with outer shadows (Extruded effect)
  // ============================================
  static BoxDecoration flat({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 16,
    Color? backgroundColor,
    bool performanceMode = false, // Performance toggle
    Border? border, // Custom border (e.g. status color for medicine cards)
    bool useDefaultBorder =
        true, // Whether to use accent border when no custom border
  }) {
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.darkCardBg : AppColors.lightCardBg);
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    // Performance mode: reduced shadows
    final dist = performanceMode ? shadowDistancePerf : shadowDistance;
    final blur = performanceMode ? shadowBlurPerf : shadowBlur;

    // Default accent border when no custom border provided
    final effectiveBorder =
        border ??
        (useDefaultBorder
            ? Border.all(
                color: (isDark ? AppColors.accentDark : AppColors.accent)
                    .withValues(alpha: AppTheme.cardBorderOpacity),
                width: AppTheme.cardBorderWidth,
              )
            : null);

    return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      border: effectiveBorder,
      boxShadow: [
        // Dark shadow (bottom-right)
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.6 : 0.6),
          offset: Offset(dist, dist),
          blurRadius: blur,
        ),
        // Light shadow (top-left)
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.1 : 1.0),
          offset: Offset(-dist, -dist),
          blurRadius: blur,
        ),
      ],
    );
  }

  // ============================================
  // FLAT SMALL - For chips, tags, small buttons
  // ============================================
  static BoxDecoration flatSmall({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 12,
    Color? backgroundColor,
    bool performanceMode = false,
  }) {
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.darkCardBg : AppColors.lightCardBg);
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    // Performance mode: reduced shadows
    final dist = performanceMode ? shadowDistanceSmPerf : shadowDistanceSm;
    final blur = performanceMode ? shadowBlurSmPerf : shadowBlurSm;

    return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.6 : 0.6),
          offset: Offset(dist, dist),
          blurRadius: blur,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.1 : 1.0),
          offset: Offset(-dist, -dist),
          blurRadius: blur,
        ),
      ],
    );
  }

  // ============================================
  // PRESSED - Sunken element (active state / Inset effect)
  // Simple flat background - use NeuInsetContainer for true inner shadows
  // ============================================
  static BoxDecoration pressed({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 16,
    Color? backgroundColor,
  }) {
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.darkCardBg : AppColors.lightCardBg);

    return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
    );
  }

  // ============================================
  // PRESSED SMALL - For small elements
  // Simple flat background - use NeuInsetContainerSmall for true inner shadows
  // ============================================
  static BoxDecoration pressedSmall({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 12,
    Color? backgroundColor,
  }) {
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.darkCardBg : AppColors.lightCardBg);

    return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
    );
  }

  // ============================================
  // BASIN - Deeply concave (inset effect)
  // Simple flat background - use NeuInsetContainer for true inner shadows
  // Used for: input fields, nested containers inside flat parents
  // ============================================
  static BoxDecoration basin({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 12,
    Color? backgroundColor,
  }) {
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.darkCardBg : AppColors.lightCardBg);

    return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
    );
  }

  // ============================================
  // CONVEX - Raised with gradient highlight
  // ============================================
  static BoxDecoration convex({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 16,
    bool performanceMode = false,
  }) {
    // Subtle gradient for convex effect
    final lightShade = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightSurface;
    final darkShade = isDark
        ? AppColors.darkSurface
        : AppColors.lightShadowDark;
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    // Performance mode: reduced shadows
    final dist = performanceMode ? shadowDistancePerf : shadowDistance;
    final blur = performanceMode ? shadowBlurPerf : shadowBlur;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightShade, darkShade],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark.withOpacity(isDark ? 0.5 : 0.25),
          offset: Offset(dist, dist),
          blurRadius: blur,
        ),
        BoxShadow(
          color: shadowLight.withOpacity(isDark ? 0.05 : 0.8),
          offset: Offset(-dist, -dist),
          blurRadius: blur,
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
    BorderRadius? borderRadius,
    double radius = 16,
    Color? paramsBorderColor, // kept for compatibility
    bool performanceMode = false,
  }) {
    // Performance mode: reduced shadows
    final blur = performanceMode ? 12.0 : 18.0;
    final offset = performanceMode ? 4.0 : 6.0;

    // Light mode: simplified - single shadow + subtle border
    if (!isDark) {
      // Determine border color from gradient (heuristic)
      Color baseColor = gradient.colors.first;
      Color borderColor = AppColors.primary.withValues(alpha: 0.12);

      // Status-aware border colors
      if (baseColor.value == 0xFF064e3b || baseColor == AppColors.valid) {
        borderColor = AppColors.valid.withValues(alpha: 0.2);
      } else if (baseColor.value == 0xFF78350f ||
          baseColor == AppColors.expiringSoon) {
        borderColor = AppColors.expiringSoon.withValues(alpha: 0.2);
      } else if (baseColor.value == 0xFF7f1d1d ||
          baseColor == AppColors.expired) {
        borderColor = AppColors.expired.withValues(alpha: 0.2);
      }

      return BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.5),
        // Single simplified shadow
        boxShadow: [
          BoxShadow(
            color: AppColors.lightShadowDark.withValues(alpha: 0.15),
            offset: Offset(offset, offset),
            blurRadius: blur,
          ),
        ],
      );
    }

    // Dark Mode: Glass Effect with border (unchanged)
    Color baseColor = gradient.colors.first;
    Color borderColor = const Color(0xFF94a3b8).withValues(alpha: 0.1);
    Color glowColor = Colors.transparent;

    if (baseColor.value == 0xFF064e3b || baseColor == AppColors.valid) {
      borderColor = const Color(0xFF10b981).withValues(alpha: 0.3);
      glowColor = const Color(0xFF10b981).withValues(alpha: 0.1);
    } else if (baseColor.value == 0xFF78350f ||
        baseColor == AppColors.expiringSoon) {
      borderColor = const Color(0xFFf59e0b).withValues(alpha: 0.3);
      glowColor = const Color(0xFFf59e0b).withValues(alpha: 0.1);
    } else if (baseColor.value == 0xFF7f1d1d ||
        baseColor == AppColors.expired) {
      borderColor = const Color(0xFFef4444).withValues(alpha: 0.3);
      glowColor = const Color(0xFFef4444).withValues(alpha: 0.1);
    }

    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: performanceMode ? 0.2 : 0.4),
          offset: const Offset(0, 8),
          blurRadius: performanceMode ? 16 : 32,
        ),
        if (glowColor != Colors.transparent)
          BoxShadow(
            color: glowColor,
            offset: const Offset(0, 0),
            blurRadius: performanceMode ? 6 : 12,
          ),
      ],
    );
  }

  // ============================================
  // PRIMARY BUTTON - Accent color (Soft UI 2026)
  // ============================================
  static BoxDecoration primaryButton({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 12,
    bool isPressed = false,
    bool performanceMode = false,
  }) {
    // Use accent colors based on theme
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final accentColor = isDark ? AppColors.accentDark : AppColors.accent;

    if (isPressed) {
      return BoxDecoration(
        color: primaryColor,
        borderRadius: borderRadius ?? BorderRadius.circular(radius),
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentColor, primaryColor],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(performanceMode ? 0.2 : 0.4),
          offset: const Offset(0, 4),
          blurRadius: performanceMode ? 6 : 12,
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
    BorderRadius? borderRadius,
    double radius = 12,
    bool isPressed = false,
    bool performanceMode = false,
  }) {
    if (isPressed) {
      return BoxDecoration(
        color: const Color(0xFFb91c1c), // red-700
        borderRadius: borderRadius ?? BorderRadius.circular(radius),
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFf87171), AppColors.expired], // red-400 to red-500
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.expired.withOpacity(performanceMode ? 0.2 : 0.4),
          offset: const Offset(0, 4),
          blurRadius: performanceMode ? 6 : 12,
          spreadRadius: -2,
        ),
      ],
    );
  }

  // ============================================
  // SEARCH BAR - Floating pill with levitation effect
  // Stronger shadows for prominent "floating" appearance
  // ============================================
  static BoxDecoration searchBar({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 32,
    bool performanceMode = false,
  }) {
    final bgColor = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    // Use standard shadow values (already strong enough)
    final dist = performanceMode ? shadowDistancePerf : shadowDistance;
    final blur = performanceMode ? shadowBlurPerf : shadowBlur;

    return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      boxShadow: [
        // Dark shadow (bottom-right) - stronger for floating effect
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.7 : 0.5),
          offset: Offset(dist, dist),
          blurRadius: blur,
        ),
        // Light shadow (top-left) - highlight for 3D effect
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.15 : 1.0),
          offset: Offset(-dist, -dist),
          blurRadius: blur,
        ),
      ],
    );
  }

  // ============================================
  // SEARCH BAR FOCUSED - Active state with accent outline
  // Reduced shadows + accent border = element "sinks" visually with accent
  // ============================================
  static BoxDecoration searchBarFocused({
    required bool isDark,
    BorderRadius? borderRadius,
    double radius = 32,
    bool performanceMode = false,
  }) {
    final bgColor = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;
    // Use accent color for focused state
    final accentColor = isDark ? AppColors.accentDark : AppColors.accent;

    return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      // Accent outline for active state
      border: Border.all(
        color: accentColor.withValues(alpha: isDark ? 0.8 : 0.6),
        width: 1.5,
      ),
      // Reduced shadows = element "sinks"
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.3 : 0.2),
          offset: const Offset(2, 2),
          blurRadius: performanceMode ? 3 : 6,
        ),
      ],
    );
  }
}
