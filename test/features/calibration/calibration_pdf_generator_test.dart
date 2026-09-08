import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/physical_length.dart';
import 'package:photo_cut/features/calibration/calibration.dart';

void main() {
  test('generates A4 PDF with an exact 50 mm reference square', () async {
    const CalibrationPdfGenerator generator = CalibrationPdfGenerator();

    final CalibrationPdfResult result = await generator.generate();
    final double expectedSquarePoints = PhysicalLength.millimetres(50)
        .inPdfPoints;

    expect(result.document.bytes, isNotEmpty);
    expect(result.document.filename, 'photo-cut-calibration-50mm.pdf');
    expect(result.document.pageWidth.inMillimetres, closeTo(210, 0.001));
    expect(result.document.pageHeight.inMillimetres, closeTo(297, 0.001));
    expect(result.squareWidthPoints, closeTo(expectedSquarePoints, 0.001));
    expect(result.squareHeightPoints, closeTo(expectedSquarePoints, 0.001));
  });
}
