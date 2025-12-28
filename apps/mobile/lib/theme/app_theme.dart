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
  static const Color lightCardValid = Color(0xFFF0FDF4);
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

  static const LinearGradient lightGradientValid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
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
  static const Color darkCardValid = Color(0xFF064e3b);
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

  static const LinearGradient darkGradientValid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064e3b), Color(0xFF065f46)],
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
    );
  }
}

/// ===========================================
/// NEUMORPHIC DECORATION HELPER
/// Klasy pomocnicze do tworzenia efektów neumorficznych
/// Dopasowane do stylu Web (globals.css)
/// ===========================================
class NeuDecoration {
  // Dystans i blur dla cieni
  static const double _neuDistance = 8.0;
  static const double _neuBlur = 16.0;
  static const double _neuDistanceSm = 4.0;
  static const double _neuBlurSm = 8.0;

  /// Flat - standardowy wypukły element (jak .neu-flat w CSS)
  static BoxDecoration flat({
    required bool isDark,
    double radius = 20,
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
          color: shadowDark,
          offset: const Offset(_neuDistance, _neuDistance),
          blurRadius: _neuBlur,
        ),
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-_neuDistance, -_neuDistance),
          blurRadius: _neuBlur,
        ),
      ],
    );
  }

  /// Concave - wklęsły element dla inputów (jak .neu-concave w CSS)
  /// Flutter nie wspiera inset shadows, więc symulujemy gradient wewnętrzny
  static BoxDecoration concave({
    required bool isDark,
    double radius = 12,
    Color? backgroundColor,
  }) {
    final bgDark = isDark ? AppColors.darkSurface : AppColors.lightSurfaceDark;
    final bgLight = isDark
        ? AppColors.darkSurfaceLight
        : AppColors.lightSurface;

    // Symulacja inset shadow przez gradient (ciemny góra-lewo, jasny dół-prawo)
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgDark, bgLight],
      ),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Convex - wypukły z gradientem (jak .neu-convex w CSS)
  static BoxDecoration convex({required bool isDark, double radius = 20}) {
    final bgLight = isDark
        ? AppColors.darkSurfaceLight
        : AppColors.lightSurface;
    final bgDark = isDark ? AppColors.darkSurface : AppColors.lightSurfaceDark;
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
        colors: [bgLight, bgDark],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark,
          offset: const Offset(_neuDistance, _neuDistance),
          blurRadius: _neuBlur,
        ),
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-_neuDistance, -_neuDistance),
          blurRadius: _neuBlur,
        ),
      ],
    );
  }

  /// Flat Small - mniejszy wariant dla tagów/chipów
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
          color: shadowDark,
          offset: const Offset(_neuDistanceSm, _neuDistanceSm),
          blurRadius: _neuBlurSm,
        ),
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-_neuDistanceSm, -_neuDistanceSm),
          blurRadius: _neuBlurSm,
        ),
      ],
    );
  }

  /// Concave Small - mniejszy wklęsły wariant
  /// Flutter nie wspiera inset shadows, więc symulujemy gradient
  static BoxDecoration concaveSmall({
    required bool isDark,
    double radius = 12,
  }) {
    final bgDark = isDark ? AppColors.darkSurface : AppColors.lightSurfaceDark;
    final bgLight = isDark
        ? AppColors.darkSurfaceLight
        : AppColors.lightSurface;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgDark, bgLight],
      ),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Card status z cieniami neumorficznymi
  /// Dla kart leków z gradientami statusu
  static BoxDecoration statusCard({
    required bool isDark,
    required LinearGradient gradient,
    double radius = 16,
    Color? borderColor,
  }) {
    if (isDark) {
      // Dark mode: subtelniejsze cienie + border
      return BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor.withValues(alpha: 0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      );
    } else {
      // Light mode: pełne cienie neumorficzne
      return BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor.withValues(alpha: 0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.lightShadowDark,
            offset: const Offset(_neuDistance, _neuDistance),
            blurRadius: _neuBlur,
          ),
          BoxShadow(
            color: AppColors.lightShadowLight,
            offset: const Offset(-_neuDistance, -_neuDistance),
            blurRadius: _neuBlur,
          ),
        ],
      );
    }
  }
}
