import 'package:flutter/material.dart';

final class PhotoCutBrand extends StatelessWidget {
  const PhotoCutBrand({
    super.key,
    this.compact = false,
    this.light = false,
    this.hero = false,
  });

  final bool compact;
  final bool light;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final double markSize = hero ? 112 : (compact ? 32 : 40);
    final TextStyle? baseStyle = hero
        ? Theme.of(context).textTheme.headlineMedium
        : compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleLarge;
    final Color photoColor = light ? Colors.white : const Color(0xFF071B4A);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox.square(
          dimension: markSize,
          child: const CustomPaint(
            key: Key('photo-cut-brand-icon'),
            painter: _PhotoCutMarkPainter(),
          ),
        ),
        SizedBox(width: hero ? 18 : 10),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: 'Photo',
                style: TextStyle(color: photoColor),
              ),
              const TextSpan(
                text: ' Cut',
                style: TextStyle(color: Color(0xFF19C6F2)),
              ),
            ],
          ),
          key: const Key('photo-cut-wordmark'),
          style: baseStyle?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: hero ? -1.1 : -0.4,
          ),
        ),
      ],
    );
  }
}

final class _PhotoCutMarkPainter extends CustomPainter {
  const _PhotoCutMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Rect outer = Rect.fromLTWH(0, 0, s, s);
    final RRect shell = RRect.fromRectAndRadius(
      outer.deflate(s * 0.025),
      Radius.circular(s * 0.22),
    );

    canvas.drawRRect(
      shell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0B57D0),
            Color(0xFF145BFF),
            Color(0xFF19C6F2),
          ],
        ).createShader(outer),
    );

    final Rect photoRect = Rect.fromLTWH(
      s * 0.24,
      s * 0.24,
      s * 0.52,
      s * 0.52,
    );
    final RRect photo = RRect.fromRectAndRadius(
      photoRect,
      Radius.circular(s * 0.075),
    );
    canvas.drawRRect(photo, Paint()..color = Colors.white);

    final Rect inner = photoRect.deflate(s * 0.035);
    final RRect innerPhoto = RRect.fromRectAndRadius(
      inner,
      Radius.circular(s * 0.045),
    );
    canvas.save();
    canvas.clipRRect(innerPhoto);
    canvas.drawRect(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF56B7FF), Color(0xFF1260D9)],
        ).createShader(inner),
    );

    final Path backMountain = Path()
      ..moveTo(inner.left + inner.width * 0.42, inner.bottom)
      ..lineTo(inner.left + inner.width * 0.72, inner.top + inner.height * 0.47)
      ..lineTo(inner.right, inner.bottom)
      ..close();
    canvas.drawPath(backMountain, Paint()..color = const Color(0xFF3D8DEB));

    final Path frontMountain = Path()
      ..moveTo(inner.left, inner.bottom)
      ..lineTo(inner.left + inner.width * 0.46, inner.top + inner.height * 0.38)
      ..lineTo(inner.left + inner.width * 0.82, inner.bottom)
      ..close();
    canvas.drawPath(frontMountain, Paint()..color = const Color(0xFF073B9C));

    canvas.drawCircle(
      Offset(inner.left + inner.width * 0.77, inner.top + inner.height * 0.24),
      s * 0.055,
      Paint()..color = const Color(0xFFF5FBFF),
    );
    canvas.restore();

    final Paint cropPaint = Paint()
      ..color = const Color(0xFFB7F4FF)
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void corner(Offset a, Offset b, Offset c) {
      final Path path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy);
      canvas.drawPath(path, cropPaint);
    }

    final double lo = s * 0.14;
    final double hi = s * 0.86;
    final double arm = s * 0.14;
    corner(Offset(lo + arm, lo), Offset(lo, lo), Offset(lo, lo + arm));
    corner(Offset(hi - arm, lo), Offset(hi, lo), Offset(hi, lo + arm));
    corner(Offset(lo, hi - arm), Offset(lo, hi), Offset(lo + arm, hi));
    corner(Offset(hi, hi - arm), Offset(hi, hi), Offset(hi - arm, hi));

    final Paint tickPaint = Paint()
      ..color = const Color(0xFF24D7F4)
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round;
    final double mid = s * 0.5;
    canvas.drawLine(Offset(mid, s * 0.10), Offset(mid, s * 0.18), tickPaint);
    canvas.drawLine(Offset(mid, s * 0.82), Offset(mid, s * 0.90), tickPaint);
    canvas.drawLine(Offset(s * 0.10, mid), Offset(s * 0.18, mid), tickPaint);
    canvas.drawLine(Offset(s * 0.82, mid), Offset(s * 0.90, mid), tickPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
