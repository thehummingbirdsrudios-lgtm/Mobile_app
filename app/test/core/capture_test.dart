import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/core/core.dart';

void main() {
  testWidgets('captures a RepaintBoundary as a PNG at the requested scale', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(width: 100, height: 50, child: ColoredBox(color: Color(0xFFFFFFFF))),
          ),
        ),
      ),
    );
    final png = await tester.runAsync(() => captureBoundary(key, pixelRatio: 3));
    final decoded = img.decodePng(png!)!;
    expect(decoded.width, 300);
    expect(decoded.height, 150);
  });

  testWidgets('capturing without a boundary fails clearly', (tester) async {
    await expectLater(captureBoundary(GlobalKey()), throwsStateError);
  });
}
