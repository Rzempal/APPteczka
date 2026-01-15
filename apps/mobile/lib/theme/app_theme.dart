import 'package:flutter/material.dart';

/// Kolory aplikacji - dopasowane do wersji webowej
/// Light Mode: miętowo-zielony (jak stary motyw)
/// Dark Mode: granatowy (jak web dark mode)
class AppColors {
  // ============================================
  // PRIMARY ACCENT - identyczny w obu motywach
  // ============================================
  static const Color primary = Color(0xFF10b981);
  static const Color primaryLight = Color(0xFF34d399);
  static const Color primaryDark = Color(0xFF059669);

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
  // LIGHT MODE COLORS
  // ============================================
  static const Color lightBackground = Color(0xFFe0e8e4);
  static const Color lightSurface = Color(0xFFedf3ef);
  static const Color lightSurfaceDark = Color(0xFFd1ddd7);
  static const Color lightText = Color(0xFF1f2937);
  static const Color lightTextMuted = Color(0xFF4b5563);
  static const Color lightShadowLight = Color(0xFFffffff);
  static const Color lightShadowDark = Color(0xFFa3b5ad);

  // Light mode card backgrounds
  static const Color lightCardExpired = Color(0xFFFEF2F2);
  static const Color lightCardExpiringSoon = Color(0xFFFFFBEB);
  // Valid: neutralny szary (jak sekcja filtrów) - nie zielony
  static const Color lightCardValid = Color(0xFFe8ece4);
  static const Color lightCardDefault = Color(0xFFF9FAFB);

  // Light mode gradients
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

  // Valid: neutralny gradient (szary) - tylko badge informuje o statusie
  static const LinearGradient lightGradientValid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFe0e6dc), Color(0xFFd4dcd0)],
  );

  // ============================================
  // DARK MODE COLORS (granatowa paleta z web)
  // ============================================
  static const Color darkBackground = Color(0xFF0f172a);
  static const Color darkSurface = Color(0xFF1e293b);
  static const Color darkSurfaceLight = Color(0xFF334155);
  static const Color darkText = Color(0xFFf1f5f9);
  static const Color darkTextMuted = Color(0xFF94a3b8);
  static const Color darkShadowLight = Color(0xFF1e293b);
  static const Color darkShadowDark = Color(0xFF070b15);

  // Dark mode card backgrounds (z przezroczystością jak w web)
  static const Color darkCardExpired = Color(0xFF7f1d1d);
  static const Color darkCardExpiringSoon = Color(0xFF78350f);
  // Valid: neutralny szary (jak tło) - nie zielony
  static const Color darkCardValid = Color(0xFF1e293b);
  static const Color darkCardDefault = Color(0xFF1e293b);

  // Dark mode gradients
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

  // Valid: neutralny gradient (szary) - tylko badge informuje o statusie
  static const LinearGradient darkGradientValid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1e293b), Color(0xFF334155)],
  );
}

/// Theme aplikacji - Light i Dark
class AppTheme {
  // ============================================
  // LIGHT THEME
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        backgroundColor: AppColors.lightSurfaceDark,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.3),
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
  // DARK THEME
  // ============================================
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        backgroundColor: AppColors.darkSurfaceLight,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.2),
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
