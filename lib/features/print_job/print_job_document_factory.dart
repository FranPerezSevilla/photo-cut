import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/features/print_job/print_job_filename_builder.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';
import 'package:photo_cut/platform/print/print.dart';

/// Produces the immutable PDF handed to preview, sharing and native printing.
final class PrintJobDocumentFactory {
  const PrintJobDocumentFactory({
    required this.imageProcessor,
    this.layoutEngine = const SheetLayoutEngine(),
    this.pdfRenderer = const ExactSizePdfRenderer(),
    this.filenameBuilder = const PrintJobFilenameBuilder(),
  });

  final PrintJobFilenameBuilder filenameBuilder;
  final ImageProcessor imageProcessor;
  final SheetLayoutEngine layoutEngine;
  final SheetPdfRenderer pdfRenderer;

  Future<PrintDocument> build(PrintJobConfiguration configuration) async {
    if (configuration.sourceSize == null) {
      throw StateError('Source image inspection must finish before PDF export');
    }

    final SheetPlan plan = layoutEngine.createPlan(
      SheetLayoutSpec(
        paperSize: configuration.paperSize,
        photoWidth: configuration.photoWidth,
        photoHeight: configuration.photoHeight,
        copyCount: configuration.copyCount,
        margin: configuration.margin,
        gap: configuration.gap,
      ),
    );
    final ProcessedImage processed = await imageProcessor.process(
      ImageProcessingRequest(
        sourceBytes: configuration.image.bytes,
        fitMode: configuration.fitMode,
        colorMode: configuration.colorMode,
        cropRect: configuration.cropRect,
        quarterTurns: plan.photoRotated ? 1 : 0,
      ),
    );
    final PdfRenderResult rendered = await pdfRenderer.render(
      plan: plan,
      imageBytes: processed.bytes,
      showCutMarks: configuration.showCutMarks,
    );

    return PrintDocument(
      bytes: rendered.bytes,
      filename: filenameBuilder.build(configuration),
      pageWidth: plan.pageWidth,
      pageHeight: plan.pageHeight,
    );
  }
}
