import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';

/// Het Bonvrij-schild met vinkje (zelfde vorm als het app-icoon).
class BonvrijLogo extends StatelessWidget {
  const BonvrijLogo({
    this.size = 72,
    this.color = AppColors.teal,
    this.checkColor = const Color(0xFFFFFFFF),
    super.key,
  });

  final double size;
  final Color color;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bonvrij-logo',
      image: true,
      child: CustomPaint(
        size: Size(size * 0.8, size),
        painter: _ShieldPainter(color, checkColor),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter(this.color, this.checkColor);

  final Color color;
  final Color checkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    const top = 0.0;
    final bottom = h;
    final shield = Path()
      ..moveTo(cx, top)
      ..cubicTo(
        cx + w * 0.18,
        top + h * 0.10,
        w - w * 0.05,
        top + h * 0.10,
        w,
        top + h * 0.12,
      )
      ..lineTo(w, cy + h * 0.02)
      ..cubicTo(w, cy + h * 0.30, cx + w * 0.25, bottom - h * 0.08, cx, bottom)
      ..cubicTo(
        cx - w * 0.25,
        bottom - h * 0.08,
        0,
        cy + h * 0.30,
        0,
        cy + h * 0.02,
      )
      ..lineTo(0, top + h * 0.12)
      ..cubicTo(
        w * 0.05,
        top + h * 0.10,
        cx - w * 0.18,
        top + h * 0.10,
        cx,
        top,
      )
      ..close();
    canvas.drawPath(shield, Paint()..color = color);

    final check = Path()
      ..moveTo(cx - h * 0.20, cy + h * 0.01)
      ..lineTo(cx - h * 0.05, cy + h * 0.16)
      ..lineTo(cx + h * 0.22, cy - h * 0.14);
    canvas.drawPath(
      check,
      Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter old) =>
      old.color != color || old.checkColor != checkColor;
}
