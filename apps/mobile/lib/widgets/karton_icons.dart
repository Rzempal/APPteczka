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

  const KartonClosedIcon({super.key, this.size = 80, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KartonClosedPainter(isDark: isDark)),
    );
  }
}

class _KartonClosedPainter extends CustomPainter {
  final bool isDark;

  _KartonClosedPainter({required this.isDark});

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
    final tapeLight = AppColors.primary;
    final tapeDark = AppColors.primaryDark;

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
    return oldDelegate.isDark != isDark;
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

    final topColor = isDark
        ? KartonColors.boxFaceTop
        : KartonColors.boxFaceTopLight;
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
    canvas.drawPath(tubePath, Paint()..color = AppColors.primaryLight);
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
class TransformationIllustration extends StatelessWidget {
  final double iconSize;
  final bool isDark;

  const TransformationIllustration({
    super.key,
    this.iconSize = 80,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neuBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final shadowDark = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.15);
    final shadowLight = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.8);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lewa ikona - bałagan (otwarte pudło)
        Container(
          width: iconSize + 32,
          height: iconSize + 32,
          decoration: BoxDecoration(
            color: neuBg,
            shape: BoxShape.circle,
            boxShadow: [
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
          child: Center(
            child: KartonOpenIcon(size: iconSize, isDark: isDark),
          ),
        ),

        // Strzałka
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            Icons.arrow_forward,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ),

        // Prawa ikona - porządek (zamknięte pudło)
        Container(
          width: iconSize + 32,
          height: iconSize + 32,
          decoration: BoxDecoration(
            color: neuBg,
            shape: BoxShape.circle,
            boxShadow: [
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
          child: Center(
            child: KartonClosedIcon(size: iconSize, isDark: isDark),
          ),
        ),
      ],
    );
  }
}
