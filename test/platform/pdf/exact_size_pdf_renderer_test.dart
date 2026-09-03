import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';

void main() {
  const ExactSizePdfRenderer renderer = ExactSizePdfRenderer();
  const double geometryToleranceMillimetres = 0.1;

  test('renders an exact A4 page and eight actual 35 x 45 mm boxes', () async {
    final SheetPlan plan = _samplePlan(copyCount: 8);
    final PdfRenderResult result = await renderer.render(
      plan: plan,
      imageBytes: _syntheticPngBytes(),
    );

    expect(ascii.decode(result.bytes.take(5).toList()), '%PDF-');
    expect(result.pages, hasLength(1));
    expect(result.pages.single.photoBoxes, hasLength(8));

    final List<_MediaBox> mediaBoxes = _readMediaBoxes(result.bytes);
    expect(mediaBoxes, hasLength(1));
    expect(
      _pointsToMillimetres(mediaBoxes.single.widthPoints),
      closeTo(210, geometryToleranceMillimetres),
    );
    expect(
      _pointsToMillimetres(mediaBoxes.single.heightPoints),
      closeTo(297, geometryToleranceMillimetres),
    );

    for (final PlacedPhoto placement in plan.placements) {
      final PdfRenderedPhotoBox renderedBox = result.pages.single.photoBoxes
          .singleWhere(
            (PdfRenderedPhotoBox box) =>
                box.copyIndex == placement.copyIndex,
          );
      _expectRenderedBoxMatchesPlan(
        renderedBox,
        placement,
        geometryToleranceMillimetres,
      );
    }
  });

  test('renders every overflow page from one synthetic image byte source', () async {
    final SheetPlan plan = _samplePlan(copyCount: 61);
    final PdfRenderResult result = await renderer.render(
      plan: plan,
      imageBytes: _syntheticPngBytes(),
    );

    expect(plan.pageCount, 3);
    expect(result.pages, hasLength(3));
    expect(_readMediaBoxes(result.bytes), hasLength(3));
    expect(result.pages[0].photoBoxes, hasLength(30));
    expect(result.pages[1].photoBoxes, hasLength(30));
    expect(result.pages[2].photoBoxes, hasLength(1));

    for (int pageIndex = 0; pageIndex < result.pages.length; pageIndex += 1) {
      expect(result.pages[pageIndex].pageIndex, pageIndex);
      expect(
        result.pages[pageIndex].photoBoxes.map((box) => box.pageIndex),
        everyElement(pageIndex),
      );
    }
  });

  test('rejects an empty image byte source before creating a document', () {
    final SheetPlan plan = _samplePlan(copyCount: 1);

    expect(
      () => renderer.render(plan: plan, imageBytes: Uint8List(0)),
      throwsArgumentError,
    );
  });
}

SheetPlan _samplePlan({required int copyCount}) {
  return const SheetLayoutEngine().createPlan(
    SheetLayoutSpec(
      paperSize: PaperSize.a4,
      photoWidth: PhysicalLength.millimetres(35),
      photoHeight: PhysicalLength.millimetres(45),
      copyCount: copyCount,
      margin: PhysicalLength.millimetres(8),
      gap: PhysicalLength.millimetres(2),
    ),
  );
}

Uint8List _syntheticPngBytes() {
  final String encoded = File(
    'test_resources/synthetic-35x45.png.base64',
  ).readAsStringSync().trim();
  return base64Decode(encoded);
}

void _expectRenderedBoxMatchesPlan(
  PdfRenderedPhotoBox renderedBox,
  PlacedPhoto placement,
  double toleranceMillimetres,
) {
  expect(
    _pointsToMillimetres(renderedBox.leftPoints),
    closeTo(placement.left.inMillimetres, toleranceMillimetres),
  );
  expect(
    _pointsToMillimetres(renderedBox.topPoints),
    closeTo(placement.top.inMillimetres, toleranceMillimetres),
  );
  expect(
    _pointsToMillimetres(renderedBox.widthPoints),
    closeTo(placement.width.inMillimetres, toleranceMillimetres),
  );
  expect(
    _pointsToMillimetres(renderedBox.heightPoints),
    closeTo(placement.height.inMillimetres, toleranceMillimetres),
  );
}

List<_MediaBox> _readMediaBoxes(Uint8List bytes) {
  final String source = latin1.decode(bytes);
  final RegExp mediaBoxPattern = RegExp(
    r'/MediaBox\s*\[\s*([-+0-9.]+)\s+([-+0-9.]+)\s+'
    r'([-+0-9.]+)\s+([-+0-9.]+)\s*\]',
  );

  return mediaBoxPattern.allMatches(source).map((RegExpMatch match) {
    final double left = double.parse(match.group(1)!);
    final double bottom = double.parse(match.group(2)!);
    final double right = double.parse(match.group(3)!);
    final double top = double.parse(match.group(4)!);
    return _MediaBox(
      widthPoints: right - left,
      heightPoints: top - bottom,
    );
  }).toList(growable: false);
}

double _pointsToMillimetres(double points) {
  return points * PhysicalLength.millimetresPerInch /
      PhysicalLength.pdfPointsPerInch;
}

final class _MediaBox {
  const _MediaBox({required this.widthPoints, required this.heightPoints});

  final double heightPoints;
  final double widthPoints;
}
