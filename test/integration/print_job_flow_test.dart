import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';
import 'package:photo_cut/platform/print/print.dart';

void main() {
  testWidgets('prepare, review, share, print and return to edit', (
    WidgetTester tester,
  ) async {
    final _FakeImageProcessor imageProcessor = _FakeImageProcessor();
    final _FakeSheetPdfRenderer pdfRenderer = _FakeSheetPdfRenderer();
    final _FakePrintGateway printGateway = _FakePrintGateway();
    final PrintJobDocumentFactory documentFactory = PrintJobDocumentFactory(
      imageProcessor: imageProcessor,
      pdfRenderer: pdfRenderer,
    );
    PrintDocument? reviewedDocument;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: PrintConfigurationScreen(
          image: _selectedImage(),
          imageProcessor: imageProcessor,
          onReview:
              (BuildContext context, PrintJobConfiguration configuration) {
                unawaited(
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext routeContext) {
                        return PrintReviewScreen(
                          configuration: configuration,
                          documentLoader: () =>
                              documentFactory.build(configuration),
                          printGateway: printGateway,
                          previewBuilder:
                              (
                                BuildContext previewContext,
                                PrintDocument document,
                              ) {
                                reviewedDocument = document;
                                return const Center(
                                  child: Text('Final PDF preview'),
                                );
                              },
                        );
                      },
                    ),
                  ),
                );
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder colorSelector = find.byKey(const Key('color-mode-selector'));
    await _scrollTo(tester, colorSelector);
    await tester.tap(find.text('Blanco y negro'));
    await tester.pump();

    final Finder widthField = find.byKey(
      const ValueKey<String>('photo-width-millimetres'),
    );
    await _scrollTo(tester, widthField);
    await tester.enterText(widthField, '40');
    await tester.pump();

    final Finder reviewButton = find.byKey(const Key('review-print-job'));
    await _scrollTo(tester, reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 2 · Revisa el PDF final'), findsOneWidget);
    expect(find.text('40 × 45 mm · 8 copias · A4'), findsOneWidget);
    expect(find.text('Final PDF preview'), findsOneWidget);
    expect(
      reviewedDocument?.filename,
      'photo-cut-synthetic-40x45mm-8copias-a4-bn.pdf',
    );
    expect(imageProcessor.request?.colorMode, ImageColorMode.grayscale);
    expect(pdfRenderer.showCutMarks, isTrue);

    await tester.tap(find.byKey(const Key('share-final-pdf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-native-print')));
    await tester.pumpAndSettle();

    expect(printGateway.shared, same(reviewedDocument));
    expect(printGateway.printed, same(reviewedDocument));

    await tester.tap(find.byKey(const Key('edit-print-job')));
    await tester.pumpAndSettle();

    expect(find.text('Preparar en Photo Cut'), findsOneWidget);
    final Finder restoredWidthField = find.byKey(
      const ValueKey<String>('photo-width-millimetres'),
    );
    await _scrollTo(tester, restoredWidthField);
    final EditableText editable = tester.widget<EditableText>(
      find.descendant(
        of: restoredWidthField,
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.controller.text, '40');
  });
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 350,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

SelectedImage _selectedImage() {
  return SelectedImage(
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
    displayName: 'synthetic.jpg',
  );
}

final class _FakeImageProcessor implements ImageProcessor {
  final SourceImageSize size = SourceImageSize(
    widthPixels: 350,
    heightPixels: 450,
  );
  ImageProcessingRequest? request;

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async => size;

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    this.request = request;
    return ProcessedImage(
      bytes: Uint8List.fromList(<int>[9, 8, 7]),
      size: size,
    );
  }
}

final class _FakeSheetPdfRenderer implements SheetPdfRenderer {
  bool? showCutMarks;

  @override
  Future<PdfRenderResult> render({
    required SheetPlan plan,
    required Uint8List imageBytes,
    bool showCutMarks = false,
  }) async {
    this.showCutMarks = showCutMarks;
    return PdfRenderResult(
      bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
      pages: <PdfRenderedPage>[],
    );
  }
}

final class _FakePrintGateway implements PrintGateway {
  PrintDocument? printed;
  PrintDocument? shared;

  @override
  Future<bool> printPdf(PrintDocument document) async {
    printed = document;
    return true;
  }

  @override
  Future<bool> sharePdf(PrintDocument document) async {
    shared = document;
    return true;
  }
}
