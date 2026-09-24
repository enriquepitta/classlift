import 'package:flutter/material.dart';

/// Decorative artwork stays separate from the form and never intercepts taps.
class LoginBackground extends StatelessWidget {
  final bool recovery;

  const LoginBackground({super.key, this.recovery = false});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child:
            CustomPaint(painter: _LoginBackgroundPainter(recovery: recovery)),
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  final bool recovery;

  const _LoginBackgroundPainter({required this.recovery});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF638FE0),
            Color(0xFFEAF3FF),
            Color(0xFFF8FAFF),
            Color(0xFFECF4FF),
            Color(0xFFA4C8FC),
          ],
          stops: [0, 0.30, 0.48, 0.76, 1],
        ).createShader(rect),
    );
    // Work in a normalized portrait space so the artwork scales with the screen.
    canvas.save();
    canvas.scale(size.width / 400, size.height / 870);
    final upperWave = Path()
      ..moveTo(160, 0)
      ..cubicTo(178, 170, 224, 170, 296, 226)
      ..cubicTo(350, 270, 350, 292, 400, 310)
      ..lineTo(400, 0)
      ..close();
    canvas.drawPath(
      upperWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xBB467BD1), Color(0x22AFD4FF)],
        ).createShader(const Rect.fromLTWH(160, 0, 240, 310)),
    );
    final lowerWave = Path()
      ..moveTo(0, 677)
      ..cubicTo(90, 710, 59, 751, 146, 783)
      ..cubicTo(210, 807, 234, 836, 244, 870)
      ..lineTo(0, 870)
      ..close();
    canvas.drawPath(
      lowerWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCEBFF), Color(0xFF83B0F5)],
        ).createShader(const Rect.fromLTWH(0, 677, 244, 193)),
    );
    final linePaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(
      Path()
        ..moveTo(-15, 87)
        ..cubicTo(90, 52, 173, 109, 212, 189),
      linePaint..color = const Color(0x22FFFFFF),
    );
    for (final offset in [0.0, 28.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(250 + offset, 885)
          ..cubicTo(282 + offset, 791, 330 + offset, 762, 421, 754 + offset),
        linePaint..color = const Color(0x66FFFFFF),
      );
    }
    if (recovery) {
      _drawEnvelope(canvas);
    } else {
      _drawCap(canvas);
    }
    final sphereCenter =
        recovery ? const Offset(278, 157) : const Offset(319, 211);
    canvas.drawCircle(
      sphereCenter,
      22,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xBBDDEEFF), Color(0x338DBBFF)],
        ).createShader(Rect.fromCircle(center: sphereCenter, radius: 22)),
    );
    final sparkle = Path()
      ..moveTo(268, 126)
      ..quadraticBezierTo(270, 135, 278, 137)
      ..quadraticBezierTo(270, 139, 268, 147)
      ..quadraticBezierTo(266, 139, 259, 137)
      ..quadraticBezierTo(266, 135, 268, 126);
    if (!recovery) {
      canvas.drawPath(sparkle, Paint()..color = const Color(0x99D7EBFF));
      canvas.drawPath(sparkle, linePaint);
    }
    // Translucent folder in the lower corner.
    canvas.save();
    canvas.translate(-30, 794);
    canvas.rotate(-0.30);
    for (var i = 0; i < 3; i++) {
      final folder = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * 3, i * 11, 104 + i * 11, 77),
        const Radius.circular(16),
      );
      canvas.drawRRect(
        folder,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xBBE2F0FF), Color(0x665C98EF)],
          ).createShader(folder.outerRect),
      );
      canvas.drawRRect(folder, linePaint..color = const Color(0x44FFFFFF));
    }
    canvas.restore();
    canvas.restore();
  }

  void _drawCap(Canvas canvas) {
    final body = Path()
      ..moveTo(322, 120)
      ..lineTo(322, 153)
      ..quadraticBezierTo(320, 168, 365, 179)
      ..quadraticBezierTo(383, 184, 397, 169)
      ..lineTo(397, 124)
      ..close();
    final top = Path()
      ..moveTo(302, 112)
      ..lineTo(352, 83)
      ..quadraticBezierTo(359, 79, 366, 82)
      ..lineTo(422, 105)
      ..quadraticBezierTo(427, 109, 420, 113)
      ..lineTo(375, 144)
      ..quadraticBezierTo(371, 148, 364, 145)
      ..lineTo(302, 120)
      ..quadraticBezierTo(296, 117, 302, 112);
    for (final path in [body, top]) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xC9D2E9FF), Color(0x806B9EED)],
          ).createShader(path.getBounds()),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x66E0F0FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(369, 121)
        ..quadraticBezierTo(373, 118, 376, 121)
        ..lineTo(391, 128)
        ..lineTo(391, 176),
      Paint()
        ..color = const Color(0xAA84B5FC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
        const Offset(391, 175), 4, Paint()..color = const Color(0xFFC0DEFF));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(386, 179, 10, 19), const Radius.circular(5)),
      Paint()..color = const Color(0xFFC0DEFF),
    );
  }

  void _drawEnvelope(Canvas canvas) {
    canvas.save();
    canvas.translate(317, 107);
    canvas.rotate(0.20);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 12, 79, 65),
      const Radius.circular(12),
    );
    final border = Paint()
      ..color = const Color(0x88E1F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4E8FF), Color(0xBB749DF4), Color(0xBBD7E9FF)],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(body, border);
    final flap = Path()
      ..moveTo(3, 13)
      ..quadraticBezierTo(0, 1, 12, 1)
      ..lineTo(67, 1)
      ..quadraticBezierTo(79, 1, 78, 13)
      ..lineTo(46, 39)
      ..quadraticBezierTo(39, 45, 32, 39)
      ..close();
    canvas.drawShadow(flap, const Color(0x886097E7), 4, false);
    canvas.drawPath(
      flap,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE1F0FF), Color(0xFFA2C4FF)],
        ).createShader(flap.getBounds()),
    );
    canvas.drawPath(flap, border);
    final ray = Paint()
      ..color = const Color(0xBBCDE6FF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(48, -10), const Offset(48, -24), ray);
    canvas.drawLine(const Offset(59, -10), const Offset(66, -20), ray);
    canvas.drawLine(const Offset(70, -6), const Offset(82, -11), ray);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoginBackgroundPainter oldDelegate) =>
      recovery != oldDelegate.recovery;
}
