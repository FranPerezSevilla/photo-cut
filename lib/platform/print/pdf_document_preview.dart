import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:photo_cut/platform/print/print_document.dart';
import 'package:printing/printing.dart';

/// Read-only preview. Share and print actions stay outside this widget so they
/// always pass through [PrintGateway].
final class PdfDocumentPreview extends StatelessWidget {
  const PdfDocumentPreview({super.key, required this.document});

  final PrintDocument document;

  @override
  Widget build(BuildContext context) {
    final PdfPageFormat format = PdfPageFormat(
      document.pageWidth.inPdfPoints,
      document.pageHeight.inPdfPoints,
      marginAll: 0,
    );

    return PdfPreview(
      build: (PdfPageFormat _) async => document.bytes,
      initialPageFormat: format,
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      dynamicLayout: false,
      useActions: false,
      pdfFileName: document.filename,
      loadingWidget: const Center(child: CircularProgressIndicator()),
      onError: (BuildContext context, Object error) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo mostrar la vista previa del PDF.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
