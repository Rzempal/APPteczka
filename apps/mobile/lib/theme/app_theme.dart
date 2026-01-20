import 'package:flutter/material.dart';

/// Kolory aplikacji - Soft UI Neumorphism 2026
/// Light Mode: Earthy Clinical (Bone White + Smoky Green)
/// Dark Mode: Innovation Indigo (Deep Indigo + Neon Mint)
class AppColors {
  // ============================================
  // PRIMARY & ACCENT - Soft UI Neumorphism 2026
  // ============================================
  // Light mode: Smoky Green
  static const Color primary = Color(0xFF3E514B);
  // Light mode: Muted Sage (accent)
  static const Color accent = Color(0xFF5D8A82);
  // Dark mode: Deep Teal (primary in dark)
  static const Color primaryDark = Color(0xFF004D40);
  // Dark mode: Neon Mint (accent in dark)
  static const Color accentDark = Color(0xFF00FF9D);

  // ============================================
  // AI ACCENT - fioletowy dla funkcji AI
  // ============================================
  static const Color aiAccentLight = Color(
    0xFF8B5CF6,
  ); // Violet-500 (light mode)
  static const Color aiAccentDark = Color(0xFF9333EA); // Purple-600 (dark mode)

  // ============================================
  // STATUS COLORS - kolory statusów ważności
  // ============================================
  static const Color expired = Color(0xFFef4444);
  static const Color expiringSoon = Color(0xFFf59e0b);
  static const Color valid = Color(0xFF22c55e);

  // ============================================
  // LIGHT MODE COLORS - Earthy Clinical
  // ============================================
  static const Color lightBackground = Color(0xFFF9F6F2); // Bone White
  static const Color lightSurface = Color(0xFFF9F6F2); // Same as background
  static const Color lightFrame = Color(0xFF3E514B); // Smoky Green (frame color)
  static const Color lightText = Color(0xFF1f2937);
  static const Color lightTextMuted = Color(0xFF4b5563);
  static const Color lightShadowLight = Color(0xFFFFFFFF); // Spec: white
  static const Color lightShadowDark = Color(0xFFE8E3D8); // Spec: darker bone

  // Light mode card backgrounds (adjusted for Bone White base)
  static const Color lightCardExpired = Color(0xFFFEF2F2);
  static const Color lightCardExpiringSoon = Color(0xFFFFFBEB);
  static const Color lightCardValid = Color(0xFFF9F6F2); // Same as background
  static const Color lightCardDefault = Color(0xFFF9F6F2); // Same as background

  // Light mode gradients (subtle, blended with Bone White)
  static const LinearGradient lightGradientExpired = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFEE2E2), Color(0xFFFECACA)],
  );

  static const LinearGradient lightGradientExpiringSoon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
  );

  // Valid: neutral gradient matching background
  static const LinearGradient lightGradientValid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF9F6F2), Color(0xFFF5F2EE)],
  );

  // ============================================
  // DARK MODE COLORS - Innovation Indigo
  // ============================================
  static const Color darkBackground = Color(0xFF1A1A2E); // Deep Indigo
  static const Color darkSurface = Color(0xFF1A1A2E); // Same as background
  static const Color darkFrame = Color(0xFF004D40); // Deep Teal (frame color)
  static const Color darkText = Color(0xFFE6E6FA); // Lavender (headline text)
  static const Color darkTextMuted = Color(0xFF94a3b8);
  static const Color darkShadowLight = Color(0xFF242442); // Spec: lighter indigo
  static const Color darkShadowDark = Color(0xFF0A0A16); // Spec: very dark indigo

  // Dark mode card backgrounds (adjusted for Deep Indigo base)
  static const Color darkCardExpired = Color(0xFF7f1d1d);
  static const Color darkCardExpiringSoon = Color(0xFF78350f);
  static const Color darkCardValid = Color(0xFF1A1A2E); // Same as background
  static const Color darkCardDefault = Color(0xFF1A1A2E); // Same as background

  // Dark mode gradients (subtle, blended with Deep Indigo)
  static const LinearGradient darkGradientExpired = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7f1d1d), Color(0xFF991b1b)],
  );

  static const LinearGradient darkGradientExpiringSoon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF78350f), Color(0xFF92400e)],
  );

  // Valid: neutral gradient matching background
  static const LinearGradient darkGradientValid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF1F1F38)],
  );
}

/// Theme aplikacji - Light i Dark
class AppTheme {
  // ============================================
  // ORGANIC GEOMETRY - Asymmetric Border Radius
  // ============================================
  /// Asymmetric radius for organic shapes: TopLeft: 50, TopRight: 50, BottomRight: 20, BottomLeft: 80
  static const BorderRadius organicRadius = BorderRadius.only(
    topLeft: Radius.circular(50),
    topRight: Radius.circular(50),
    bottomRight: Radius.circular(20),
    bottomLeft: Radius.circular(80),
  );

  /// Smaller organic radius for cards and components
  static const BorderRadius organicRadiusSmall = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
    bottomRight: Radius.circular(12),
    bottomLeft: Radius.circular(36),
  );

  /// Organic radius for bottom sheets (only top corners)
  static const BorderRadius organicRadiusBottomSheet = BorderRadius.only(
    topLeft: Radius.circular(50),
    topRight: Radius.circular(50),
    bottomRight: Radius.zero,
    bottomLeft: Radius.zero,
  );

  /// Organic radius for bottom sheet inner content
  static const BorderRadius organicRadiusBottomSheetInner = BorderRadius.only(
    topLeft: Radius.circular(36),
    topRight: Radius.circular(36),
    bottomRight: Radius.circular(12),
    bottomLeft: Radius.circular(24),
  );

  // ============================================
  // LIGHT THEME - Earthy Clinical
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary, // Smoky Green
        secondary: AppColors.accent, // Muted Sage
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        onSurfaceVariant: AppColors.lightTextMuted,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: organicRadiusSmall),
        color: AppColors.lightSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightShadowDark, // Subtle background
        selectedColor: AppColors.accent, // Muted Sage accent
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.accent.withValues(alpha: 0.3),
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      dividerColor: AppColors.lightShadowDark,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: false, // Używamy własnego BottomSheetDragHandle
      ),
    );
  }

  // ============================================
  // DARK THEME - Innovation Indigo
  // ============================================
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDark, // Deep Teal
        secondary: AppColors.accentDark, // Neon Mint
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText, // Lavender
        onSurfaceVariant: AppColors.darkTextMuted,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: organicRadiusSmall),
        color: AppColors.darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkShadowLight, // Subtle background
        selectedColor: AppColors.accentDark, // Neon Mint accent
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.accentDark.withValues(alpha: 0.2),
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      dividerColor: AppColors.darkShadowDark,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: false, // Używamy własnego BottomSheetDragHandle
      ),
    );
  }
}

// NeuDecoration class moved to widgets/neumorphic/neu_decoration.dart
// Import: import '../widgets/neumorphic/neumorphic.dart';
