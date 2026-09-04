import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/platform/pdf/pdf_render_result.dart';
import 'package:photo_cut/platform/pdf/sheet_pdf_renderer.dart';

/// Renders a domain [SheetPlan] without reimplementing any placement logic.
final class ExactSizePdfRenderer implements SheetPdfRenderer {
  const ExactSizePdfRenderer();

  @override
  Future<PdfRenderResult> render({
    required SheetPlan plan,
    required Uint8List imageBytes,
    bool showCutMarks = false,
  }) async {
    if (imageBytes.isEmpty) {
      throw ArgumentError.value(
        imageBytes,
        'imageBytes',
        'Image bytes must not be empty',
      );
    }

    final pw.MemoryImage image = pw.MemoryImage(imageBytes);
    final pw.Document document = pw.Document(
      compress: false,
      version: PdfVersion.pdf_1_4,
      title: 'Photo Cut exact-size sheet',
      creator: 'Photo Cut',
      producer: 'Photo Cut using pdf 3.13.0',
    );
    final List<_TrackedPage> trackedPages = <_TrackedPage>[];

    for (int pageIndex = 0; pageIndex < plan.pageCount; pageIndex += 1) {
      final PdfPageFormat pageFormat = PdfPageFormat(
        plan.pageWidth.inPdfPoints,
        plan.pageHeight.inPdfPoints,
        marginAll: 0,
      );
      final List<_TrackedPhoto> trackedPhotos = <_TrackedPhoto>[];
      final List<pw.Widget> children = <pw.Widget>[];

      for (final PlacedPhoto placement in plan.placementsForPage(pageIndex)) {
        final pw.Positioned positioned = pw.Positioned(
          left: placement.left.inPdfPoints,
          top: placement.top.inPdfPoints,
          child: pw.Container(
            width: placement.width.inPdfPoints,
            height: placement.height.inPdfPoints,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: showCutMarks
                  ? pw.Border.all(color: PdfColors.black, width: 0.25)
                  : null,
            ),
            child: pw.Image(
              image,
              width: placement.width.inPdfPoints,
              height: placement.height.inPdfPoints,
              fit: pw.BoxFit.contain,
            ),
          ),
        );
        trackedPhotos.add(
          _TrackedPhoto(placement: placement, positioned: positioned),
        );
        children.add(positioned);
      }

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          clip: true,
          build: (pw.Context context) {
            return pw.Stack(
              fit: pw.StackFit.expand,
              overflow: pw.Overflow.clip,
              children: children,
            );
          },
        ),
      );
      trackedPages.add(
        _TrackedPage(
          pageIndex: pageIndex,
          pageFormat: pageFormat,
          photos: trackedPhotos,
        ),
      );
    }

    final Uint8List bytes = await document.save();
    final List<PdfRenderedPage> pages = trackedPages
        .map(_measurePage)
        .toList(growable: false);

    return PdfRenderResult(bytes: bytes, pages: pages);
  }

  static PdfRenderedPage _measurePage(_TrackedPage trackedPage) {
    final List<PdfRenderedPhotoBox> boxes = trackedPage.photos
        .map((tracked) {
          final PdfRect? box = tracked.positioned.box;
          if (box == null) {
            throw StateError(
              'PDF layout did not produce a box for copy '
              '${tracked.placement.copyIndex}',
            );
          }

          return PdfRenderedPhotoBox(
            copyIndex: tracked.placement.copyIndex,
            pageIndex: tracked.placement.pageIndex,
            leftPoints: box.left,
            topPoints: trackedPage.pageFormat.height - box.top,
            widthPoints: box.width,
            heightPoints: box.height,
          );
        })
        .toList(growable: false);

    return PdfRenderedPage(
      pageIndex: trackedPage.pageIndex,
      widthPoints: trackedPage.pageFormat.width,
      heightPoints: trackedPage.pageFormat.height,
      photoBoxes: boxes,
    );
  }
}

final class _TrackedPage {
  const _TrackedPage({
    required this.pageIndex,
    required this.pageFormat,
    required this.photos,
  });

  final PdfPageFormat pageFormat;
  final int pageIndex;
  final List<_TrackedPhoto> photos;
}

final class _TrackedPhoto {
  const _TrackedPhoto({required this.placement, required this.positioned});

  final PlacedPhoto placement;
  final pw.Positioned positioned;
}
