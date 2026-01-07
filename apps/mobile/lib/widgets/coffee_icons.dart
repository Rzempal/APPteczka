import 'package:flutter/material.dart';

/// Custom coffee icons for BuyCoffee support section.
/// Based on SVG designs from docs/buycoffee/icon_coffee.html
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
    final iconColor = color ?? const Color(0xFF4A8B5F); // BuyCoffee green

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
    final scale = canvasSize.width / 24; // SVG viewBox is 0 0 24 24

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.6 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withAlpha(13)
      ..style = PaintingStyle.fill;

    switch (size) {
      case CoffeeSize.small:
        _drawEspresso(canvas, scale, strokePaint, fillPaint);
        break;
      case CoffeeSize.medium:
        _drawCappuccino(canvas, scale, strokePaint, fillPaint);
        break;
      case CoffeeSize.large:
        _drawTakeaway(canvas, scale, strokePaint, fillPaint);
        break;
    }
  }

  /// Espresso - small cup with steam
  void _drawEspresso(
    Canvas canvas,
    double scale,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    // Steam lines
    final steamPaint = Paint()
      ..color = strokePaint.color.withAlpha(153)
      ..strokeWidth = 1.2 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Steam 1
    final steam1 = Path()
      ..moveTo(9 * scale, 2 * scale)
      ..cubicTo(
        9 * scale,
        2 * scale,
        9.5 * scale,
        3 * scale,
        9 * scale,
        4 * scale,
      )
      ..cubicTo(
        8.5 * scale,
        5 * scale,
        9 * scale,
        6 * scale,
        9 * scale,
        6 * scale,
      );
    canvas.drawPath(steam1, steamPaint);

    // Steam 2
    final steam2 = Path()
      ..moveTo(12 * scale, 1 * scale)
      ..cubicTo(
        12 * scale,
        1 * scale,
        12.5 * scale,
        2 * scale,
        12 * scale,
        3 * scale,
      )
      ..cubicTo(
        11.5 * scale,
        4 * scale,
        12 * scale,
        5 * scale,
        12 * scale,
        5 * scale,
      );
    canvas.drawPath(steam2, steamPaint);

    // Cup body fill
    final cupPath = Path()
      ..moveTo(6 * scale, 9 * scale)
      ..lineTo(15 * scale, 9 * scale)
      ..lineTo(15 * scale, 12.5 * scale)
      ..arcToPoint(
        Offset(6 * scale, 12.5 * scale),
        radius: Radius.circular(4.5 * scale),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(cupPath, fillPaint);
    canvas.drawPath(cupPath, strokePaint);

    // Handle
    final handle = Path()
      ..moveTo(15 * scale, 10 * scale)
      ..lineTo(16.5 * scale, 10 * scale)
      ..arcToPoint(
        Offset(16.5 * scale, 15 * scale),
        radius: Radius.circular(2.5 * scale),
        clockwise: true,
      )
      ..lineTo(15 * scale, 15 * scale);
    canvas.drawPath(handle, strokePaint);

    // Saucer
    canvas.drawLine(
      Offset(4 * scale, 19 * scale),
      Offset(17 * scale, 19 * scale),
      strokePaint,
    );
  }

  /// Cappuccino - wide cup with latte art heart
  void _drawCappuccino(
    Canvas canvas,
    double scale,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    // Steam lines
    final steamPaint = Paint()
      ..color = strokePaint.color.withAlpha(153)
      ..strokeWidth = 1.2 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Steam 1
    final steam1 = Path()
      ..moveTo(8 * scale, 2 * scale)
      ..cubicTo(
        8 * scale,
        2 * scale,
        8.5 * scale,
        3 * scale,
        8 * scale,
        4 * scale,
      )
      ..cubicTo(
        7.5 * scale,
        5 * scale,
        8 * scale,
        6 * scale,
        8 * scale,
        6 * scale,
      );
    canvas.drawPath(steam1, steamPaint);

    // Steam 2
    final steam2 = Path()
      ..moveTo(11 * scale, 1 * scale)
      ..cubicTo(
        11 * scale,
        1 * scale,
        11.5 * scale,
        2 * scale,
        11 * scale,
        3 * scale,
      )
      ..cubicTo(
        10.5 * scale,
        4 * scale,
        11 * scale,
        5 * scale,
        11 * scale,
        5 * scale,
      );
    canvas.drawPath(steam2, steamPaint);

    // Steam 3
    final steam3 = Path()
      ..moveTo(14 * scale, 2 * scale)
      ..cubicTo(
        14 * scale,
        2 * scale,
        14.5 * scale,
        3 * scale,
        14 * scale,
        4 * scale,
      )
      ..cubicTo(
        13.5 * scale,
        5 * scale,
        14 * scale,
        6 * scale,
        14 * scale,
        6 * scale,
      );
    canvas.drawPath(steam3, steamPaint);

    // Wide cup body
    final cupPath = Path()
      ..moveTo(3 * scale, 8 * scale)
      ..lineTo(17 * scale, 8 * scale)
      ..lineTo(17 * scale, 12.5 * scale)
      ..quadraticBezierTo(17 * scale, 19 * scale, 10 * scale, 19 * scale)
      ..lineTo(9 * scale, 19 * scale)
      ..quadraticBezierTo(3 * scale, 19 * scale, 3 * scale, 12.5 * scale)
      ..close();
    canvas.drawPath(cupPath, fillPaint);
    canvas.drawPath(cupPath, strokePaint);

    // Latte art heart
    final heartPaint = Paint()
      ..color = strokePaint.color.withAlpha(77)
      ..style = PaintingStyle.fill;

    final heartPath = Path()
      ..moveTo(10 * scale, 14.3 * scale)
      ..cubicTo(
        10 * scale,
        13.7 * scale,
        9.6 * scale,
        11.4 * scale,
        8.8 * scale,
        11.4 * scale,
      )
      ..cubicTo(
        8 * scale,
        11.4 * scale,
        8 * scale,
        12.2 * scale,
        10 * scale,
        14.3 * scale,
      )
      ..moveTo(10 * scale, 14.3 * scale)
      ..cubicTo(
        10 * scale,
        13.7 * scale,
        10.4 * scale,
        11.4 * scale,
        11.2 * scale,
        11.4 * scale,
      )
      ..cubicTo(
        12 * scale,
        11.4 * scale,
        12 * scale,
        12.2 * scale,
        10 * scale,
        14.3 * scale,
      );
    canvas.drawPath(heartPath, heartPaint);

    // Handle
    final handle = Path()
      ..moveTo(17 * scale, 9 * scale)
      ..lineTo(19 * scale, 9 * scale)
      ..arcToPoint(
        Offset(19 * scale, 15 * scale),
        radius: Radius.circular(3 * scale),
        clockwise: true,
      )
      ..lineTo(17 * scale, 15 * scale);
    canvas.drawPath(handle, strokePaint);

    // Saucer
    canvas.drawLine(
      Offset(2 * scale, 22 * scale),
      Offset(20 * scale, 22 * scale),
      strokePaint,
    );
  }

  /// Takeaway - tall cup with lid
  void _drawTakeaway(
    Canvas canvas,
    double scale,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    // Cup body
    final cupPath = Path()
      ..moveTo(6 * scale, 7 * scale)
      ..lineTo(7.5 * scale, 20.5 * scale)
      ..quadraticBezierTo(7.6 * scale, 21.3 * scale, 8.4 * scale, 22 * scale)
      ..lineTo(15.6 * scale, 22 * scale)
      ..quadraticBezierTo(
        16.4 * scale,
        21.3 * scale,
        16.5 * scale,
        20.5 * scale,
      )
      ..lineTo(18 * scale, 7 * scale)
      ..close();
    canvas.drawPath(cupPath, fillPaint);
    canvas.drawPath(cupPath, strokePaint);

    // Lid
    final lidPath = Path()
      ..moveTo(5 * scale, 7 * scale)
      ..lineTo(19 * scale, 7 * scale)
      ..lineTo(19 * scale, 6 * scale)
      ..quadraticBezierTo(19 * scale, 4 * scale, 17 * scale, 4 * scale)
      ..lineTo(7 * scale, 4 * scale)
      ..quadraticBezierTo(5 * scale, 4 * scale, 5 * scale, 6 * scale)
      ..close();
    canvas.drawPath(lidPath, strokePaint);

    // Lid spout
    final spoutPath = Path()
      ..moveTo(14 * scale, 4 * scale)
      ..lineTo(14 * scale, 2.5 * scale)
      ..quadraticBezierTo(14 * scale, 2 * scale, 13.5 * scale, 2 * scale)
      ..lineTo(10.5 * scale, 2 * scale)
      ..quadraticBezierTo(10 * scale, 2 * scale, 10 * scale, 2.5 * scale)
      ..lineTo(10 * scale, 4 * scale);
    canvas.drawPath(spoutPath, strokePaint);

    // Sleeve bands
    final bandPaint = Paint()
      ..color = strokePaint.color.withAlpha(204)
      ..strokeWidth = 1 * scale
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(6.5 * scale, 12 * scale),
      Offset(17.5 * scale, 12 * scale),
      bandPaint,
    );
    canvas.drawLine(
      Offset(7.2 * scale, 17 * scale),
      Offset(16.8 * scale, 17 * scale),
      bandPaint,
    );

    // Sleeve texture lines
    final texturePaint = Paint()
      ..color = strokePaint.color.withAlpha(102)
      ..strokeWidth = 0.8 * scale
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(9.5 * scale, 12 * scale),
      Offset(10 * scale, 17 * scale),
      texturePaint,
    );
    canvas.drawLine(
      Offset(12 * scale, 12 * scale),
      Offset(12 * scale, 17 * scale),
      texturePaint,
    );
    canvas.drawLine(
      Offset(14.5 * scale, 12 * scale),
      Offset(14 * scale, 17 * scale),
      texturePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoffeePainter oldDelegate) {
    return oldDelegate.size != size || oldDelegate.color != color;
  }
}
