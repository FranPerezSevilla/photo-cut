import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';

void main() {
  test('cut marks keep every exact outer photo rectangle unchanged', () async {
    final SheetPlan plan = const SheetLayoutEngine().createPlan(
      SheetLayoutSpec(
        paperSize: PaperSize.a4,
        photoWidth: PhysicalLength.millimetres(35),
        photoHeight: PhysicalLength.millimetres(45),
        copyCount: 8,
        margin: PhysicalLength.millimetres(8),
        gap: PhysicalLength.millimetres(2),
      ),
    );
    final Uint8List imageBytes = base64Decode(
      File('test_resources/synthetic-35x45.png.base64')
          .readAsStringSync()
          .trim(),
    );

    final PdfRenderResult result = await const ExactSizePdfRenderer().render(
      plan: plan,
      imageBytes: imageBytes,
      showCutMarks: true,
    );

    expect(result.pages, hasLength(1));
    expect(result.pages.single.photoBoxes, hasLength(8));
    for (final PlacedPhoto placement in plan.placements) {
      final PdfRenderedPhotoBox box = result.pages.single.photoBoxes
          .singleWhere(
            (PdfRenderedPhotoBox candidate) =>
                candidate.copyIndex == placement.copyIndex,
          );
      expect(box.widthPoints, closeTo(placement.width.inPdfPoints, 0.01));
      expect(box.heightPoints, closeTo(placement.height.inPdfPoints, 0.01));
    }
  });
}
