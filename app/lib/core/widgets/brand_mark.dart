import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// The Vepari mark: a faceted-gem "V" on an ink tile. Same geometry as
/// brand/vepari-logo.svg (512-unit grid) so app, icon and splash match.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.semanticLabel = 'Vepari'});

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _BrandPainter()),
      ),
    );
  }
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter();

  static const _goldLight = Color(0xFFD7B46A);
  static const _goldDark = AppColors.gold;
  static const _spark = AppColors.goldTint;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Path poly(List<Offset> points) => Path()..addPolygon(points, true);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(112 * s)),
      Paint()..color = AppColors.ink,
    );
    canvas.drawPath(poly([p(128, 160), p(208, 160), p(256, 296), p(256, 384)]), Paint()..color = _goldLight);
    canvas.drawPath(poly([p(304, 160), p(384, 160), p(256, 384), p(256, 296)]), Paint()..color = _goldDark);
    canvas.drawPath(poly([p(256, 88), p(276, 118), p(256, 148), p(236, 118)]), Paint()..color = _spark);
  }

  @override
  bool shouldRepaint(_BrandPainter oldDelegate) => false;
}
