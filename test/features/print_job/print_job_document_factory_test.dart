import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';

void main() {
  test('builds one stable named document from all final settings', () async {
    final _FakeImageProcessor imageProcessor = _FakeImageProcessor();
    final _FakeSheetPdfRenderer pdfRenderer = _FakeSheetPdfRenderer();
    final PrintJobDocumentFactory factory = PrintJobDocumentFactory(
      imageProcessor: imageProcessor,
      pdfRenderer: pdfRenderer,
    );
    final PrintJobConfiguration configuration = _configuration();

    final document = await factory.build(configuration);

    expect(document.filename, 'photo-cut-mi-foto-na-35x45mm-8copias-a4-bn.pdf');
    expect(document.bytes, <int>[37, 80, 68, 70, 45]);
    expect(document.pageWidth, pdfRenderer.plan?.pageWidth);
    expect(document.pageHeight, pdfRenderer.plan?.pageHeight);
    expect(pdfRenderer.showCutMarks, isTrue);
    expect(pdfRenderer.imageBytes, <int>[9, 8, 7]);

    final ImageProcessingRequest? request = imageProcessor.request;
    expect(request, isNotNull);
    expect(request?.fitMode, ImageFitMode.cropToFill);
    expect(request?.colorMode, ImageColorMode.grayscale);
    expect(request?.cropRect, configuration.cropRect);
    expect(request?.quarterTurns, pdfRenderer.plan!.photoRotated ? 1 : 0);
  });

  test('final PDF honors forced landscape paper orientation', () async {
    final _FakeSheetPdfRenderer pdfRenderer = _FakeSheetPdfRenderer();
    final PrintJobDocumentFactory factory = PrintJobDocumentFactory(
      imageProcessor: _FakeImageProcessor(),
      pdfRenderer: pdfRenderer,
    );
    final PrintJobConfiguration configuration = _configuration(
      pageOrientationPreference: PageOrientationPreference.landscape,
    );

    await factory.build(configuration);

    expect(pdfRenderer.plan?.pageOrientation, PageOrientation.landscape);
    expect(pdfRenderer.plan?.pageWidth.inMillimetres, closeTo(297, 0.000001));
    expect(pdfRenderer.plan?.pageHeight.inMillimetres, closeTo(210, 0.000001));
  });

  test('final PDF honors custom paper dimensions', () async {
    final _FakeSheetPdfRenderer pdfRenderer = _FakeSheetPdfRenderer();
    final PrintJobDocumentFactory factory = PrintJobDocumentFactory(
      imageProcessor: _FakeImageProcessor(),
      pdfRenderer: pdfRenderer,
    );
    final PrintJobConfiguration configuration = _configuration(
      paperSize: PaperSize.custom(
        width: PhysicalLength.millimetres(120),
        height: PhysicalLength.millimetres(180),
      ),
      pageOrientationPreference: PageOrientationPreference.landscape,
    );

    final document = await factory.build(configuration);

    expect(pdfRenderer.plan?.paperSize.isCustom, isTrue);
    expect(document.pageWidth.inMillimetres, closeTo(180, 0.000001));
    expect(document.pageHeight.inMillimetres, closeTo(120, 0.000001));
    expect(document.filename, contains('custom-120x180mm'));
  });

  test('filename is deterministic and strips unsafe source characters', () {
    const PrintJobFilenameBuilder builder = PrintJobFilenameBuilder();
    final PrintJobConfiguration configuration = _configuration();

    expect(builder.build(configuration), builder.build(configuration));
    expect(builder.build(configuration), isNot(contains(' ')));
    expect(builder.build(configuration), isNot(contains('/')));
    expect(builder.build(configuration), endsWith('.pdf'));
  });

  test('refuses to export before source inspection has completed', () async {
    final PrintJobConfiguration configuration = _configuration().copyWith(
      sourceSize: null,
    );
    final PrintJobDocumentFactory factory = PrintJobDocumentFactory(
      imageProcessor: _FakeImageProcessor(),
      pdfRenderer: _FakeSheetPdfRenderer(),
    );

    await expectLater(factory.build(configuration), throwsA(isA<StateError>()));
  });
}

PrintJobConfiguration _configuration({
  PageOrientationPreference pageOrientationPreference =
      PageOrientationPreference.automatic,
  PaperSize? paperSize,
}) {
  return PrintJobConfiguration(
    image: SelectedImage(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      displayName: 'Mi foto ñá!!.jpeg',
    ),
    photoWidth: PhysicalLength.millimetres(35),
    photoHeight: PhysicalLength.millimetres(45),
    paperSize: paperSize ?? PaperSize.a4,
    pageOrientationPreference: pageOrientationPreference,
    copyCount: 8,
    margin: PhysicalLength.millimetres(8),
    gap: PhysicalLength.millimetres(2),
    showCutMarks: true,
    fitMode: ImageFitMode.cropToFill,
    colorMode: ImageColorMode.grayscale,
    focus: NormalizedPoint.center,
    cropRect: NormalizedCropRect.full,
    sourceSize: SourceImageSize(widthPixels: 350, heightPixels: 450),
  );
}

final class _FakeImageProcessor implements ImageProcessor {
  ImageProcessingRequest? request;

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async {
    return SourceImageSize(widthPixels: 350, heightPixels: 450);
  }

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    this.request = request;
    return ProcessedImage(
      bytes: Uint8List.fromList(<int>[9, 8, 7]),
      size: SourceImageSize(widthPixels: 350, heightPixels: 450),
    );
  }
}

final class _FakeSheetPdfRenderer implements SheetPdfRenderer {
  Uint8List? imageBytes;
  SheetPlan? plan;
  bool? showCutMarks;

  @override
  Future<PdfRenderResult> render({
    required SheetPlan plan,
    required Uint8List imageBytes,
    bool showCutMarks = false,
  }) async {
    this.plan = plan;
    this.imageBytes = Uint8List.fromList(imageBytes);
    this.showCutMarks = showCutMarks;
    return PdfRenderResult(
      bytes: Uint8List.fromList(<int>[37, 80, 68, 70, 45]),
      pages: <PdfRenderedPage>[],
    );
  }
}
