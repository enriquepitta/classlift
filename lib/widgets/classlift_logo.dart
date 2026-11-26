import 'package:flutter/material.dart';

/// Scalable ClassLift mark: an open book and an upward arrow.
class ClassliftLogo extends StatelessWidget {
  final double size;
  final double bookProgress;
  final double arrowProgress;

  const ClassliftLogo({
    super.key,
    this.size = 144,
    this.bookProgress = 1,
    this.arrowProgress = 1,
  })  : assert(bookProgress >= 0 && bookProgress <= 1),
        assert(arrowProgress >= 0 && arrowProgress <= 1);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Logo de ClassLift',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.27),
          boxShadow: [
            BoxShadow(
              color: const Color(0x335486D0),
              blurRadius: size * 0.28,
              offset: Offset(0, size * 0.14),
            ),
            BoxShadow(
              color: const Color(0x125D93E4),
              blurRadius: size * 0.07,
              offset: Offset(0, size * 0.03),
            ),
          ],
        ),
        child: CustomPaint(
          size: Size.square(size),
          painter: _ClassliftMarkPainter(bookProgress, arrowProgress),
        ),
      ),
    );
  }
}

/// Draw the mark synchronously, including during the very first startup frame.
/// The matching SVG in assets/icons/classlift_mark.svg remains available for export.
class _ClassliftMarkPainter extends CustomPainter {
  final double bookProgress;
  final double arrowProgress;

  const _ClassliftMarkPainter(this.bookProgress, this.arrowProgress);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 128, size.height / 128);
    final tile = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 1, 126, 126),
      const Radius.circular(34),
    );
    canvas.drawRRect(
        tile,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF82BBFF), Color(0xFF4F94F4), Color(0xFF2E65DA)],
            stops: [0, 0.48, 1],
          ).createShader(tile.outerRect));
    canvas.drawPath(
      Path()
        ..moveTo(2, 60)
        ..lineTo(2, 35)
        ..cubicTo(2, 16.8, 16.8, 2, 35, 2)
        ..lineTo(93, 2)
        ..cubicTo(111.2, 2, 126, 16.8, 126, 35)
        ..lineTo(126, 46)
        ..cubicTo(88, 24, 54, 75, 2, 60)
        ..close(),
      Paint()..color = const Color(0x17FFFFFF),
    );
    canvas.drawRRect(
        tile,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xCCFFFFFF), Color(0x1FFFFFFF)],
          ).createShader(tile.outerRect));
    // Open both leaves around the spine; the tile is visible from frame one.
    canvas.save();
    canvas.translate(64, 0);
    canvas.scale(0.22 + 0.78 * bookProgress, 1);
    canvas.translate(-64, 0);
    canvas.drawPath(
      Path()
        ..moveTo(26, 48)
        ..cubicTo(37, 47, 47, 50, 58, 57)
        ..lineTo(58, 96)
        ..cubicTo(47, 88, 38, 84, 26, 84)
        ..close(),
      Paint()..color = const Color(0xF0FFFFFF),
    );
    canvas.drawPath(
      Path()
        ..moveTo(70, 57)
        ..cubicTo(81, 50, 91, 47, 102, 48)
        ..lineTo(102, 84)
        ..cubicTo(90, 84, 81, 88, 70, 96)
        ..close(),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFD1E7FF)],
        ).createShader(const Rect.fromLTWH(70, 43, 32, 53)),
    );
    canvas.restore();
    final arrow = Path()
      ..moveTo(64, 66)
      ..lineTo(64, 28)
      ..moveTo(51, 41)
      ..lineTo(64, 28)
      ..lineTo(77, 41);
    final metrics = arrow.computeMetrics().toList();
    var remaining =
        metrics.fold<double>(0, (sum, m) => sum + m.length) * arrowProgress;
    final drawnArrow = Path();
    for (final metric in metrics) {
      if (remaining <= 0) break;
      drawnArrow.addPath(
          metric.extractPath(0, remaining.clamp(0, metric.length)),
          Offset.zero);
      remaining -= metric.length;
    }
    canvas.drawPath(
      drawnArrow,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(34, 97)
        ..cubicTo(45, 98, 54, 101, 64, 107)
        ..cubicTo(74, 101, 83, 98, 94, 97),
      Paint()
        ..color = Color.lerp(
            Colors.transparent, const Color(0x8CBCDFFF), bookProgress)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClassliftMarkPainter oldDelegate) =>
      bookProgress != oldDelegate.bookProgress ||
      arrowProgress != oldDelegate.arrowProgress;
}
