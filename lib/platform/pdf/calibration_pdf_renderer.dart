import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/print/print.dart';

/// Measured PDF-space geometry of the 50 mm calibration reference.
final class CalibrationSquareGeometry {
  const CalibrationSquareGeometry({
    required this.leftPoints,
    required this.topPoints,
    required this.widthPoints,
    required this.heightPoints,
  });

  final double heightPoints;
  final double leftPoints;
  final double topPoints;
  final double widthPoints;
}

/// Immutable calibration PDF plus the actual laid-out reference rectangle.
final class CalibrationPdfResult {
  const CalibrationPdfResult({
    required this.document,
    required this.square,
  });

  final PrintDocument document;
  final CalibrationSquareGeometry square;
}

/// Generates a deterministic 50 mm square on a selected supported paper size.
final class CalibrationPdfRenderer {
  const CalibrationPdfRenderer();

  static final PhysicalLength referenceSize = PhysicalLength.millimetres(50);
  static final PhysicalLength squareTop = PhysicalLength.millimetres(15);
  static final PhysicalLength horizontalTextMargin =
      PhysicalLength.millimetres(12);

  Future<CalibrationPdfResult> render(PaperSize paperSize) async {
    final double pageWidth = paperSize.width.inPdfPoints;
    final double pageHeight = paperSize.height.inPdfPoints;
    final double squareSize = referenceSize.inPdfPoints;
    final double squareLeft = (pageWidth - squareSize) / 2;
    final double squareTopPoints = squareTop.inPdfPoints;
    final PdfPageFormat pageFormat = PdfPageFormat(
      pageWidth,
      pageHeight,
      marginAll: 0,
    );

    final pw.Positioned trackedSquare = pw.Positioned(
      left: squareLeft,
      top: squareTopPoints,
      child: pw.Container(
        width: squareSize,
        height: squareSize,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5),
        ),
      ),
    );

    final double textTop =
        squareTopPoints + squareSize + PhysicalLength.millimetres(8).inPdfPoints;
    final double textWidth =
        pageWidth - 2 * horizontalTextMargin.inPdfPoints;
    final pw.Document pdf = pw.Document(
      compress: false,
      version: PdfVersion.pdf_1_4,
      title: 'Photo Cut 50 mm calibration',
      creator: 'Photo Cut',
      producer: 'Photo Cut using pdf 3.13.0',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        clip: true,
        build: (pw.Context context) {
          return pw.Stack(
            fit: pw.StackFit.expand,
            children: <pw.Widget>[
              trackedSquare,
              pw.Positioned(
                left: horizontalTextMargin.inPdfPoints,
                top: textTop,
                child: pw.Container(
                  width: textWidth,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        'Photo Cut calibration',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Reference square: 50 mm x 50 mm'),
                      pw.SizedBox(height: 4),
                      pw.Text('Print at 100% / Actual size.'),
                      pw.Text('Do not use Fit to page.'),
                      pw.SizedBox(height: 4),
                      pw.Text('Measure both sides with a ruler.'),
                    ],
                  ),
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
      throw StateError('Calibration PDF did not lay out the reference square');
    }

    return CalibrationPdfResult(
      document: PrintDocument(
        bytes: bytes,
        filename: 'photo-cut-calibracion-${paperSize.id}-50mm.pdf',
        pageWidth: paperSize.width,
        pageHeight: paperSize.height,
      ),
      square: CalibrationSquareGeometry(
        leftPoints: box.left,
        topPoints: pageFormat.height - box.top,
        widthPoints: box.width,
        heightPoints: box.height,
      ),
    );
  }
}
