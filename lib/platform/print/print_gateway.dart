import 'package:photo_cut/platform/print/print_document.dart';

/// Boundary around native printing and platform share sheets.
abstract interface class PrintGateway {
  Future<bool> printPdf(PrintDocument document);

  Future<bool> sharePdf(PrintDocument document);
}
