import 'package:pdf/pdf.dart';
import 'package:photo_cut/platform/print/print_document.dart';
import 'package:photo_cut/platform/print/print_gateway.dart';
import 'package:printing/printing.dart';

/// Native implementation backed by the `printing` Flutter plugin.
final class PrintingPrintGateway implements PrintGateway {
  const PrintingPrintGateway();

  @override
  Future<bool> printPdf(PrintDocument document) {
    final PdfPageFormat format = PdfPageFormat(
      document.pageWidth.inPdfPoints,
      document.pageHeight.inPdfPoints,
      marginAll: 0,
    );

    return Printing.layoutPdf(
      name: document.documentName,
      format: format,
      dynamicLayout: false,
      onLayout: (PdfPageFormat _) async => document.bytes,
    );
  }

  @override
  Future<bool> sharePdf(PrintDocument document) {
    return Printing.sharePdf(
      bytes: document.bytes,
      filename: document.filename,
    );
  }
}
