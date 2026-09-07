import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';

void main() {
  const CalibrationPdfRenderer renderer = CalibrationPdfRenderer();
  const double toleranceMillimetres = 0.1;

  for (final PaperSize paper in PaperSize.presets) {
    test('renders an exact 50 mm square on ${paper.id}', () async {
      final CalibrationPdfResult result = await renderer.render(paper);

      expect(ascii.decode(result.document.bytes.take(5).toList()), '%PDF-');
      expect(result.document.pageWidth, paper.width);
      expect(result.document.pageHeight, paper.height);
      expect(
        _pointsToMillimetres(result.square.widthPoints),
        closeTo(50, toleranceMillimetres),
      );
      expect(
        _pointsToMillimetres(result.square.heightPoints),
        closeTo(50, toleranceMillimetres),
      );
      expect(result.square.leftPoints, greaterThanOrEqualTo(0));
      expect(result.square.topPoints, greaterThanOrEqualTo(0));
      expect(
        result.square.leftPoints + result.square.widthPoints,
        lessThanOrEqualTo(paper.width.inPdfPoints + 0.001),
      );
      expect(
        result.square.topPoints + result.square.heightPoints,
        lessThanOrEqualTo(paper.height.inPdfPoints + 0.001),
      );

      final _MediaBox mediaBox = _readSingleMediaBox(result.document.bytes);
      expect(
        _pointsToMillimetres(mediaBox.widthPoints),
        closeTo(paper.width.inMillimetres, toleranceMillimetres),
      );
      expect(
        _pointsToMillimetres(mediaBox.heightPoints),
        closeTo(paper.height.inMillimetres, toleranceMillimetres),
      );
    });
  }
}

_MediaBox _readSingleMediaBox(List<int> bytes) {
  final String source = latin1.decode(bytes);
  final RegExp pattern = RegExp(
    r'/MediaBox\s*\[\s*([-+0-9.]+)\s+([-+0-9.]+)\s+'
    r'([-+0-9.]+)\s+([-+0-9.]+)\s*\]',
  );
  final List<RegExpMatch> matches = pattern.allMatches(source).toList();
  expect(matches, hasLength(1));
  final RegExpMatch match = matches.single;
  final double left = double.parse(match.group(1)!);
  final double bottom = double.parse(match.group(2)!);
  final double right = double.parse(match.group(3)!);
  final double top = double.parse(match.group(4)!);
  return _MediaBox(
    widthPoints: right - left,
    heightPoints: top - bottom,
  );
}

double _pointsToMillimetres(double points) {
  return points *
      PhysicalLength.millimetresPerInch /
      PhysicalLength.pdfPointsPerInch;
}

final class _MediaBox {
  const _MediaBox({required this.widthPoints, required this.heightPoints});

  final double heightPoints;
  final double widthPoints;
}
