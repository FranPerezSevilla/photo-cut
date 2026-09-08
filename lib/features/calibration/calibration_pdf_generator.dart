import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photo_cut/core/units/physical_length.dart';
import 'package:photo_cut/platform/print/print_document.dart';

/// Generated calibration PDF together with measured layout evidence.
final class CalibrationPdfResult {
  const CalibrationPdfResult({
    required this.document,
    required this.squareWidthPoints,
    required this.squareHeightPoints,
  });

  final PrintDocument document;
  final double squareWidthPoints;
  final double squareHeightPoints;
}

/// Builds an A4 calibration sheet containing an exact 50 x 50 mm reference.
final class CalibrationPdfGenerator {
  const CalibrationPdfGenerator();

  static final PhysicalLength pageWidth = PhysicalLength.millimetres(210);
  static final PhysicalLength pageHeight = PhysicalLength.millimetres(297);
  static final PhysicalLength referenceSize = PhysicalLength.millimetres(50);
  static final PhysicalLength referenceLeft = PhysicalLength.millimetres(30);
  static final PhysicalLength referenceTop = PhysicalLength.millimetres(42);

  Future<CalibrationPdfResult> generate() async {
    final PdfPageFormat pageFormat = PdfPageFormat(
      pageWidth.inPdfPoints,
      pageHeight.inPdfPoints,
      marginAll: 0,
    );
    final pw.Document pdf = pw.Document(
      compress: false,
      version: PdfVersion.pdf_1_4,
      title: 'Photo Cut calibration sheet',
      creator: 'Photo Cut',
      producer: 'Photo Cut using pdf 3.13.0',
    );

    late final pw.Positioned trackedSquare;
    trackedSquare = pw.Positioned(
      left: referenceLeft.inPdfPoints,
      top: referenceTop.inPdfPoints,
      child: pw.Container(
        width: referenceSize.inPdfPoints,
        height: referenceSize.inPdfPoints,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5),
        ),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            fit: pw.StackFit.expand,
            children: <pw.Widget>[
              trackedSquare,
              pw.Positioned(
                left: referenceLeft.inPdfPoints,
                top: referenceTop.inPdfPoints + referenceSize.inPdfPoints + 16,
                child: pw.Text(
                  '50 mm x 50 mm',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Positioned(
                left: referenceLeft.inPdfPoints,
                top: referenceTop.inPdfPoints + referenceSize.inPdfPoints + 34,
                child: pw.Text(
                  'Print at 100% / Actual size. Do not fit to page.',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final PdfRect? box = trackedSquare.box;
    if (box == null) {
      throw StateError('Calibration PDF did not lay out the reference square.');
    }

    return CalibrationPdfResult(
      document: PrintDocument(
        bytes: bytes,
        filename: 'photo-cut-calibration-50mm.pdf',
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      ),
      squareWidthPoints: box.width,
      squareHeightPoints: box.height,
    );
  }
}
