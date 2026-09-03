import 'dart:typed_data';

/// Actual page and photo rectangles produced by the PDF widget layout pass.
///
/// Values use PDF points, where 72 points equal one inch.
final class PdfRenderedPhotoBox {
  const PdfRenderedPhotoBox({
    required this.copyIndex,
    required this.pageIndex,
    required this.leftPoints,
    required this.topPoints,
    required this.widthPoints,
    required this.heightPoints,
  });

  final int copyIndex;
  final double heightPoints;
  final double leftPoints;
  final int pageIndex;
  final double topPoints;
  final double widthPoints;

  Map<String, Object> toJson() {
    return <String, Object>{
      'copyIndex': copyIndex,
      'pageIndex': pageIndex,
      'leftPoints': leftPoints,
      'topPoints': topPoints,
      'widthPoints': widthPoints,
      'heightPoints': heightPoints,
    };
  }
}

/// Actual geometry emitted for one PDF page.
final class PdfRenderedPage {
  PdfRenderedPage({
    required this.pageIndex,
    required this.widthPoints,
    required this.heightPoints,
    required List<PdfRenderedPhotoBox> photoBoxes,
  }) : photoBoxes = List<PdfRenderedPhotoBox>.unmodifiable(photoBoxes);

  final double heightPoints;
  final int pageIndex;
  final List<PdfRenderedPhotoBox> photoBoxes;
  final double widthPoints;

  Map<String, Object> toJson() {
    return <String, Object>{
      'pageIndex': pageIndex,
      'widthPoints': widthPoints,
      'heightPoints': heightPoints,
      'photoBoxes': photoBoxes
          .map((PdfRenderedPhotoBox photoBox) => photoBox.toJson())
          .toList(growable: false),
    };
  }
}

/// Generated PDF bytes plus geometry measured after the PDF layout pass.
final class PdfRenderResult {
  PdfRenderResult({
    required this.bytes,
    required List<PdfRenderedPage> pages,
  }) : pages = List<PdfRenderedPage>.unmodifiable(pages);

  final Uint8List bytes;
  final List<PdfRenderedPage> pages;

  Map<String, Object> geometryToJson() {
    return <String, Object>{
      'pageCount': pages.length,
      'pages': pages
          .map((PdfRenderedPage page) => page.toJson())
          .toList(growable: false),
    };
  }
}
