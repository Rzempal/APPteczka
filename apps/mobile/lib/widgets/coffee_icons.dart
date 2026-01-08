import 'package:flutter/material.dart';

/// Custom coffee icons matching official BuyCoffee.to design.
/// ViewBox: 0 0 36 36, stroke-width: 2
class CoffeeIcon extends StatelessWidget {
  final CoffeeSize size;
  final double dimension;
  final Color? color;

  const CoffeeIcon({
    super.key,
    required this.size,
    this.dimension = 36,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? const Color(0xFF00B67A); // BuyCoffee green

    return SizedBox(
      width: dimension,
      height: dimension,
      child: CustomPaint(
        painter: _CoffeePainter(size: size, color: iconColor),
      ),
    );
  }
}

enum CoffeeSize { small, medium, large }

class _CoffeePainter extends CustomPainter {
  final CoffeeSize size;
  final Color color;

  _CoffeePainter({required this.size, required this.color});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final scale = canvasSize.width / 36; // Official viewBox is 0 0 36 36

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (size) {
      case CoffeeSize.small:
        _drawSmallCoffee(canvas, scale, strokePaint);
        break;
      case CoffeeSize.medium:
        _drawMediumCoffee(canvas, scale, strokePaint);
        break;
      case CoffeeSize.large:
        _drawLargeCoffee(canvas, scale, strokePaint);
        break;
    }
  }

  /// Small coffee - espresso cup (based on BuyCoffee coffee-small.svg)
  void _drawSmallCoffee(Canvas canvas, double scale, Paint strokePaint) {
    // Cup body - rounded bottom
    final cupPath = Path()
      ..moveTo(8 * scale, 12 * scale)
      ..lineTo(8 * scale, 22 * scale)
      ..quadraticBezierTo(8 * scale, 28 * scale, 14 * scale, 28 * scale)
      ..lineTo(18 * scale, 28 * scale)
      ..quadraticBezierTo(24 * scale, 28 * scale, 24 * scale, 22 * scale)
      ..lineTo(24 * scale, 12 * scale);
    canvas.drawPath(cupPath, strokePaint);

    // Cup rim
    canvas.drawLine(
      Offset(6 * scale, 12 * scale),
      Offset(26 * scale, 12 * scale),
      strokePaint,
    );

    // Handle
    final handlePath = Path()
      ..moveTo(24 * scale, 14 * scale)
      ..quadraticBezierTo(30 * scale, 14 * scale, 30 * scale, 20 * scale)
      ..quadraticBezierTo(30 * scale, 26 * scale, 24 * scale, 26 * scale);
    canvas.drawPath(handlePath, strokePaint);

    // Steam - single wavy line
    final steamPath = Path()
      ..moveTo(16 * scale, 4 * scale)
      ..quadraticBezierTo(14 * scale, 6 * scale, 16 * scale, 8 * scale)
      ..quadraticBezierTo(18 * scale, 10 * scale, 16 * scale, 12 * scale);
    canvas.drawPath(steamPath, strokePaint);
  }

  /// Medium coffee - cappuccino cup (based on BuyCoffee coffee-medium.svg)
  void _drawMediumCoffee(Canvas canvas, double scale, Paint strokePaint) {
    // Cup body - wider, rounded
    final cupPath = Path()
      ..moveTo(6 * scale, 12 * scale)
      ..lineTo(6 * scale, 22 * scale)
      ..quadraticBezierTo(6 * scale, 30 * scale, 14 * scale, 30 * scale)
      ..lineTo(18 * scale, 30 * scale)
      ..quadraticBezierTo(26 * scale, 30 * scale, 26 * scale, 22 * scale)
      ..lineTo(26 * scale, 12 * scale);
    canvas.drawPath(cupPath, strokePaint);

    // Cup rim
    canvas.drawLine(
      Offset(4 * scale, 12 * scale),
      Offset(28 * scale, 12 * scale),
      strokePaint,
    );

    // Handle
    final handlePath = Path()
      ..moveTo(26 * scale, 14 * scale)
      ..quadraticBezierTo(32 * scale, 14 * scale, 32 * scale, 21 * scale)
      ..quadraticBezierTo(32 * scale, 28 * scale, 26 * scale, 28 * scale);
    canvas.drawPath(handlePath, strokePaint);

    // Steam - two wavy lines
    final steam1 = Path()
      ..moveTo(12 * scale, 4 * scale)
      ..quadraticBezierTo(10 * scale, 6 * scale, 12 * scale, 8 * scale)
      ..quadraticBezierTo(14 * scale, 10 * scale, 12 * scale, 12 * scale);
    canvas.drawPath(steam1, strokePaint);

    final steam2 = Path()
      ..moveTo(20 * scale, 4 * scale)
      ..quadraticBezierTo(18 * scale, 6 * scale, 20 * scale, 8 * scale)
      ..quadraticBezierTo(22 * scale, 10 * scale, 20 * scale, 12 * scale);
    canvas.drawPath(steam2, strokePaint);
  }

  /// Large coffee - takeaway cup (based on BuyCoffee coffee-large.svg)
  void _drawLargeCoffee(Canvas canvas, double scale, Paint strokePaint) {
    // Cup body - tall, slightly tapered
    final cupPath = Path()
      ..moveTo(8 * scale, 8 * scale)
      ..lineTo(10 * scale, 30 * scale)
      ..lineTo(26 * scale, 30 * scale)
      ..lineTo(28 * scale, 8 * scale);
    canvas.drawPath(cupPath, strokePaint);

    // Lid
    final lidPath = Path()
      ..moveTo(6 * scale, 8 * scale)
      ..lineTo(30 * scale, 8 * scale)
      ..lineTo(29 * scale, 4 * scale)
      ..lineTo(7 * scale, 4 * scale)
      ..close();
    canvas.drawPath(lidPath, strokePaint);

    // Lid top/spout
    canvas.drawLine(
      Offset(14 * scale, 4 * scale),
      Offset(22 * scale, 4 * scale),
      strokePaint,
    );

    // Sleeve band
    canvas.drawLine(
      Offset(9 * scale, 16 * scale),
      Offset(27 * scale, 16 * scale),
      strokePaint,
    );
    canvas.drawLine(
      Offset(10 * scale, 24 * scale),
      Offset(26 * scale, 24 * scale),
      strokePaint,
    );

    // Steam - three wavy lines
    final steam1 = Path()
      ..moveTo(14 * scale, -2 * scale)
      ..quadraticBezierTo(12 * scale, 0 * scale, 14 * scale, 2 * scale);
    canvas.drawPath(steam1, strokePaint);

    final steam2 = Path()
      ..moveTo(18 * scale, -4 * scale)
      ..quadraticBezierTo(16 * scale, -2 * scale, 18 * scale, 0 * scale)
      ..quadraticBezierTo(20 * scale, 2 * scale, 18 * scale, 4 * scale);
    canvas.drawPath(steam2, strokePaint);

    final steam3 = Path()
      ..moveTo(22 * scale, -2 * scale)
      ..quadraticBezierTo(20 * scale, 0 * scale, 22 * scale, 2 * scale);
    canvas.drawPath(steam3, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CoffeePainter oldDelegate) {
    return oldDelegate.size != size || oldDelegate.color != color;
  }
}
