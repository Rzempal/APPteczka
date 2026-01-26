import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kolory kartonu - zgodne z Karton-svg.html
class KartonColors {
  // Dark mode (domyślne)
  static const Color boxFaceTop = Color(0xFFE6C590);
  static const Color boxFaceRight = Color(0xFFD4B070);
  static const Color boxFaceLeft = Color(0xFFC29B55);
  static const Color boxInner = Color(0xFF654321);
  static const Color boxFlap = Color(0xFFB08D55);

  // Akcenty leków
  static const Color itemBottle = Color(0xFFF59E0B);
  static const Color itemBottleDark = Color(0xFFD97706);
  static const Color itemCap = Color(0xFFF1F5F9);
  static const Color itemBox = Color(0xFFFFFFFF);
  static const Color itemBoxSide = Color(0xFFCBD5E1);
  static const Color itemBlister = Color(0xFF94A3B8);

  // Light mode
  static const Color boxFaceTopLight = Color(0xFFFFE5B4);
  static const Color boxFaceRightLight = Color(0xFFFFD180);
  static const Color boxFaceLeftLight = Color(0xFFFFB74D);
  static const Color boxInnerLight = Color(0xFF8D5E2A);
  static const Color boxFlapLight = Color(0xFFE0C090);
}

/// Ikona zamkniętego kartonu z krzyżem medycznym (uporządkowany)
class KartonClosedIcon extends StatelessWidget {
  final double size;
  final bool isDark;
  final Color?
  accentColor; // Optional override for tape/cross color (e.g., red for DEV)

  const KartonClosedIcon({
    super.key,
    this.size = 80,
    this.isDark = true,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KartonClosedPainter(isDark: isDark, accentColor: accentColor),
      ),
    );
  }
}

class _KartonClosedPainter extends CustomPainter {
  final bool isDark;
  final Color? accentColor;

  _KartonClosedPainter({required this.isDark, this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    canvas.save();
    canvas.translate(10 * scale, 10 * scale);
    canvas.scale(0.9 * scale);

    final topColor = isDark
        ? KartonColors.boxFaceTop
        : KartonColors.boxFaceTopLight;
    final leftColor = isDark
        ? KartonColors.boxFaceLeft
        : KartonColors.boxFaceLeftLight;
    final rightColor = isDark
        ? KartonColors.boxFaceRight
        : KartonColors.boxFaceRightLight;
    // Use accentColor if provided, otherwise default to AppColors.primary
    final tapeLight = accentColor ?? AppColors.primary;
    final tapeDark = accentColor != null
        ? HSLColor.fromColor(accentColor!).withLightness(0.35).toColor()
        : AppColors.primaryDark;

    // Góra kartonu
    final topPath = Path()
      ..moveTo(100, 24)
      ..lineTo(186, 64)
      ..lineTo(100, 104)
      ..lineTo(14, 64)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);

    // Taśma na górze
    final tapeTopPath = Path()
      ..moveTo(35, 73.8)
      ..lineTo(65, 87.7)
      ..lineTo(151, 47.7)
      ..lineTo(121, 33.8)
      ..close();
    canvas.drawPath(tapeTopPath, Paint()..color = tapeLight);

    // Lewy bok kartonu
    final leftPath = Path()
      ..moveTo(12, 68)
      ..lineTo(98, 108)
      ..lineTo(98, 186)
      ..lineTo(12, 146)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = leftColor);

    // Taśma na lewym boku
    final tapeLeftPath = Path()
      ..moveTo(35, 78.7)
      ..lineTo(65, 92.7)
      ..lineTo(65, 140)
      ..lineTo(35, 125)
      ..close();
    canvas.drawPath(tapeLeftPath, Paint()..color = tapeDark);

    // Prawy bok kartonu
    final rightPath = Path()
      ..moveTo(188, 68)
      ..lineTo(188, 146)
      ..lineTo(102, 186)
      ..lineTo(102, 108)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = rightColor);

    // Krzyż medyczny na prawym boku (skew)
    canvas.save();
    canvas.translate(145, 127);
    // Skew transformation matrix for -25 degrees
    final skewMatrix = Matrix4.identity()..setEntry(1, 0, -0.466); // tan(-25°)
    canvas.transform(skewMatrix.storage);

    final crossPaint = Paint()..color = tapeLight;
    // Pozioma belka krzyża
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, -8, 50, 16),
        const Radius.circular(1),
      ),
      crossPaint,
    );
    // Pionowa belka krzyża
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -25, 16, 50),
        const Radius.circular(1),
      ),
      crossPaint,
    );
    canvas.restore();

    // Łącznik taśmy
    final tapeConnectorPath = Path()
      ..moveTo(35, 73.8)
      ..lineTo(65, 87.7)
      ..lineTo(65, 92.7)
      ..lineTo(35, 78.7)
      ..close();
    canvas.drawPath(tapeConnectorPath, Paint()..color = tapeDark);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KartonClosedPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Ikona zamkniętego kartonu - wersja monochromatyczna (dla nav bar)
/// Kolor dziedziczony z kontekstu (currentColor pattern)
/// Opacity warstw zgodne z HTML: top 0.15, left 0.5, right 0.3, tape/cross 1.0
class KartonMonoClosedIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const KartonMonoClosedIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KartonMonoClosedPainter(color: effectiveColor),
      ),
    );
  }
}

class _KartonMonoClosedPainter extends CustomPainter {
  final Color color;

  _KartonMonoClosedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    canvas.save();
    canvas.translate(10 * scale, 10 * scale);
    canvas.scale(0.9 * scale);

    // Góra kartonu (opacity 0.15)
    final topPath = Path()
      ..moveTo(100, 24)
      ..lineTo(186, 64)
      ..lineTo(100, 104)
      ..lineTo(14, 64)
      ..close();
    canvas.drawPath(topPath, Paint()..color = color.withValues(alpha: 0.15));

    // Taśma na górze (opacity 1.0)
    final tapeTopPath = Path()
      ..moveTo(35, 73.8)
      ..lineTo(65, 87.7)
      ..lineTo(151, 47.7)
      ..lineTo(121, 33.8)
      ..close();
    canvas.drawPath(tapeTopPath, Paint()..color = color);

    // Lewy bok kartonu (opacity 0.5)
    final leftPath = Path()
      ..moveTo(12, 68)
      ..lineTo(98, 108)
      ..lineTo(98, 186)
      ..lineTo(12, 146)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = color.withValues(alpha: 0.5));

    // Taśma na lewym boku (opacity 1.0)
    final tapeLeftPath = Path()
      ..moveTo(35, 78.7)
      ..lineTo(65, 92.7)
      ..lineTo(65, 140)
      ..lineTo(35, 125)
      ..close();
    canvas.drawPath(tapeLeftPath, Paint()..color = color);

    // Prawy bok kartonu (opacity 0.3)
    final rightPath = Path()
      ..moveTo(188, 68)
      ..lineTo(188, 146)
      ..lineTo(102, 186)
      ..lineTo(102, 108)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = color.withValues(alpha: 0.3));

    // Krzyż medyczny na prawym boku (opacity 1.0)
    canvas.save();
    canvas.translate(145, 127);
    final skewMatrix = Matrix4.identity()..setEntry(1, 0, -0.466); // tan(-25°)
    canvas.transform(skewMatrix.storage);

    final crossPaint = Paint()..color = color;
    // Pozioma belka krzyża
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, -8, 50, 16),
        const Radius.circular(1),
      ),
      crossPaint,
    );
    // Pionowa belka krzyża
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -25, 16, 50),
        const Radius.circular(1),
      ),
      crossPaint,
    );
    canvas.restore();

    // Łącznik taśmy (opacity 1.0)
    final tapeConnectorPath = Path()
      ..moveTo(35, 73.8)
      ..lineTo(65, 87.7)
      ..lineTo(65, 92.7)
      ..lineTo(35, 78.7)
      ..close();
    canvas.drawPath(tapeConnectorPath, Paint()..color = color);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KartonMonoClosedPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Ikona otwartego kartonu z lekami (bałagan)
class KartonOpenIcon extends StatelessWidget {
  final double size;
  final bool isDark;

  const KartonOpenIcon({super.key, this.size = 80, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KartonOpenPainter(isDark: isDark)),
    );
  }
}

class _KartonOpenPainter extends CustomPainter {
  final bool isDark;

  _KartonOpenPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    canvas.save();
    canvas.translate(10 * scale, 15 * scale);
    canvas.scale(0.9 * scale);

    final leftColor = isDark
        ? KartonColors.boxFaceLeft
        : KartonColors.boxFaceLeftLight;
    final rightColor = isDark
        ? KartonColors.boxFaceRight
        : KartonColors.boxFaceRightLight;
    final innerColor = isDark
        ? KartonColors.boxInner
        : KartonColors.boxInnerLight;
    final flapColor = isDark ? KartonColors.boxFlap : KartonColors.boxFlapLight;

    // Tylne klapy (otwarte)
    final flapLeftPath = Path()
      ..moveTo(14, 64)
      ..lineTo(100, 34)
      ..lineTo(85, 5)
      ..lineTo(5, 30)
      ..close();
    canvas.drawPath(flapLeftPath, Paint()..color = flapColor.withOpacity(0.9));

    final flapRightPath = Path()
      ..moveTo(186, 64)
      ..lineTo(100, 34)
      ..lineTo(115, 5)
      ..lineTo(195, 30)
      ..close();
    canvas.drawPath(flapRightPath, Paint()..color = flapColor.withOpacity(0.9));

    // Wnętrze kartonu
    final innerPath = Path()
      ..moveTo(100, 108)
      ..lineTo(186, 64)
      ..lineTo(100, 34)
      ..lineTo(14, 64)
      ..close();
    canvas.drawPath(innerPath, Paint()..color = innerColor);

    // Butelka (w centrum)
    canvas.save();
    canvas.translate(100, 45);
    canvas.rotate(5 * 3.14159 / 180); // 5 degrees

    // Korpus butelki
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, 0, 24, 42),
        const Radius.circular(4),
      ),
      Paint()..color = KartonColors.itemBottle,
    );
    // Cień butelki
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, 0, 8, 42),
        const Radius.circular(4),
      ),
      Paint()..color = KartonColors.itemBottleDark,
    );
    // Nakrętka
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, -8, 28, 8),
        const Radius.circular(2),
      ),
      Paint()..color = KartonColors.itemCap,
    );
    // Etykieta
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, 10, 16, 20),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    canvas.restore();

    // Przednie ściany kartonu
    final leftWallPath = Path()
      ..moveTo(12, 68)
      ..lineTo(98, 108)
      ..lineTo(98, 186)
      ..lineTo(12, 146)
      ..close();
    canvas.drawPath(leftWallPath, Paint()..color = leftColor);

    final rightWallPath = Path()
      ..moveTo(188, 68)
      ..lineTo(188, 146)
      ..lineTo(102, 186)
      ..lineTo(102, 108)
      ..close();
    canvas.drawPath(rightWallPath, Paint()..color = rightColor);

    // Tubka (lewy górny róg)
    canvas.save();
    canvas.translate(45, 55);
    canvas.rotate(45 * 3.14159 / 180);
    // Nakrętka tubki
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, 25, 16, 8),
        const Radius.circular(1),
      ),
      Paint()..color = KartonColors.itemCap,
    );
    // Korpus tubki
    final tubePath = Path()
      ..moveTo(-10, 25)
      ..lineTo(10, 25)
      ..lineTo(8, -15)
      ..lineTo(-8, -15)
      ..close();
    canvas.drawPath(tubePath, Paint()..color = AppColors.accent);
    // Cień tubki
    final tubeShadowPath = Path()
      ..moveTo(-10, 25)
      ..lineTo(0, 25)
      ..lineTo(0, -15)
      ..lineTo(-8, -15)
      ..close();
    canvas.drawPath(tubeShadowPath, Paint()..color = AppColors.primaryDark);
    canvas.restore();

    // Pudełko leku (prawy górny róg)
    canvas.save();
    canvas.translate(155, 65);
    canvas.rotate(-25 * 3.14159 / 180);
    // Bok pudełka
    final boxSidePath = Path()
      ..moveTo(-12, -18)
      ..lineTo(-20, -24)
      ..lineTo(-20, 12)
      ..lineTo(-12, 18)
      ..close();
    canvas.drawPath(boxSidePath, Paint()..color = KartonColors.itemBoxSide);
    // Front pudełka
    canvas.drawRect(
      const Rect.fromLTWH(-12, -18, 24, 36),
      Paint()..color = KartonColors.itemBox,
    );
    // Góra pudełka
    final boxTopPath = Path()
      ..moveTo(-12, -18)
      ..lineTo(12, -18)
      ..lineTo(4, -24)
      ..lineTo(-20, -24)
      ..close();
    canvas.drawPath(boxTopPath, Paint()..color = Colors.white);
    // Znaczek na pudełku
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, -6, 12, 12),
        const Radius.circular(1),
      ),
      Paint()..color = AppColors.primary.withOpacity(0.9),
    );
    canvas.restore();

    // Blister (lewy górny)
    canvas.save();
    canvas.translate(75, 15);
    canvas.rotate(-20 * 3.14159 / 180);
    // Tło blistra
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -24, 36, 48),
        const Radius.circular(4),
      ),
      Paint()..color = KartonColors.itemBlister,
    );
    // Obramowanie blistra
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -22, 32, 44),
        const Radius.circular(3),
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Pigułki
    final pillPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(const Offset(-9, -12), 5, pillPaint);
    canvas.drawCircle(const Offset(-9, 0), 5, pillPaint);
    canvas.drawCircle(const Offset(-9, 12), 5, pillPaint);
    canvas.drawCircle(const Offset(9, -12), 5, pillPaint);
    canvas.drawCircle(const Offset(9, 0), 5, pillPaint);
    canvas.drawCircle(const Offset(9, 12), 5, pillPaint);
    canvas.restore();

    // Krzyż na prawym boku
    canvas.save();
    canvas.translate(145, 127);
    final skewMatrix = Matrix4.identity()..setEntry(1, 0, -0.466);
    canvas.transform(skewMatrix.storage);
    final crossPaint = Paint()..color = AppColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -6, 40, 12),
        const Radius.circular(1),
      ),
      crossPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, -20, 12, 40),
        const Radius.circular(1),
      ),
      crossPaint,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KartonOpenPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

/// Widget ilustracji transformacji: bałagan → porządek
/// Z animacją pressed i callbackami do zmiany nagłówka
class TransformationIllustration extends StatefulWidget {
  final double iconSize;
  final bool isDark;
  final ValueChanged<int>?
  onIconTap; // 0 = left (bałagan), 1 = right (porządek)

  const TransformationIllustration({
    super.key,
    this.iconSize = 80,
    this.isDark = true,
    this.onIconTap,
  });

  @override
  State<TransformationIllustration> createState() =>
      _TransformationIllustrationState();
}

class _TransformationIllustrationState extends State<TransformationIllustration>
    with TickerProviderStateMixin {
  bool _leftPressed = false;
  bool _rightPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Użyj kolorów z AppColors dla spójności z aplikacją
    final neuBg = widget.isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final shadowDark = widget.isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;
    final shadowLight = widget.isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lewa ikona - bałagan (otwarte pudło)
        _buildIconButton(
          isPressed: _leftPressed,
          onTapDown: () => setState(() => _leftPressed = true),
          onTapUp: () {
            setState(() => _leftPressed = false);
            widget.onIconTap?.call(0);
          },
          onTapCancel: () => setState(() => _leftPressed = false),
          neuBg: neuBg,
          shadowDark: shadowDark,
          shadowLight: shadowLight,
          child: KartonOpenIcon(size: widget.iconSize, isDark: widget.isDark),
        ),

        // Strzałka
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            Icons.arrow_forward,
            size: 28,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),

        // Prawa ikona - porządek (zamknięte pudło)
        _buildIconButton(
          isPressed: _rightPressed,
          onTapDown: () => setState(() => _rightPressed = true),
          onTapUp: () {
            setState(() => _rightPressed = false);
            widget.onIconTap?.call(1);
          },
          onTapCancel: () => setState(() => _rightPressed = false),
          neuBg: neuBg,
          shadowDark: shadowDark,
          shadowLight: shadowLight,
          child: KartonClosedIcon(size: widget.iconSize, isDark: widget.isDark),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
    required Color neuBg,
    required Color shadowDark,
    required Color shadowLight,
    required Widget child,
  }) {
    final containerSize = widget.iconSize + 32;

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: neuBg,
            shape: BoxShape.circle,
            boxShadow: isPressed
                ? [
                    // Pressed - mniejsze cienie (efekt wciśnięcia)
                    BoxShadow(
                      color: shadowDark,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: shadowLight,
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ]
                : [
                    // Normal - wypukłe cienie
                    BoxShadow(
                      color: shadowDark,
                      offset: const Offset(6, 6),
                      blurRadius: 12,
                    ),
                    BoxShadow(
                      color: shadowLight,
                      offset: const Offset(-6, -6),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
