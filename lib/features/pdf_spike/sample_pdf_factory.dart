import 'dart:convert';
import 'dart:typed_data';

import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';
import 'package:photo_cut/platform/print/print_document.dart';

/// Builds the deterministic document used to prove preview/share/print wiring.
final class SamplePdfFactory {
  const SamplePdfFactory({
    this.layoutEngine = const SheetLayoutEngine(),
    this.renderer = const ExactSizePdfRenderer(),
  });

  static const String filename = 'photo-cut-sample-35x45-a4.pdf';

  final SheetLayoutEngine layoutEngine;
  final ExactSizePdfRenderer renderer;

  Future<PrintDocument> build() async {
    final SheetPlan plan = layoutEngine.createPlan(
      SheetLayoutSpec(
        paperSize: PaperSize.a4,
        photoWidth: PhysicalLength.millimetres(35),
        photoHeight: PhysicalLength.millimetres(45),
        copyCount: 8,
        margin: PhysicalLength.millimetres(8),
        gap: PhysicalLength.millimetres(2),
      ),
    );
    final Uint8List imageBytes = base64Decode(_syntheticPngBase64);
    final PdfRenderResult result = await renderer.render(
      plan: plan,
      imageBytes: imageBytes,
    );

    return PrintDocument(
      bytes: result.bytes,
      filename: filename,
      pageWidth: plan.pageWidth,
      pageHeight: plan.pageHeight,
    );
  }

  static const String _syntheticPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAACMAAAAtCAIAAACrsUV+AAAARElEQVR42u3VsREAEBRE'
      'wc+oQyXKEQkUqAwVaUFCtK+Bnbnk0m4tvpTjVyQSiUR6VRm9Wo9EIpFIl68Ra1qP'
      'RCKRSHcdIZ4DvGdT4rYAAAAASUVORK5CYII=';
}
