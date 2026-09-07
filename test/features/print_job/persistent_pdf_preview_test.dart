import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';
import 'package:photo_cut/platform/print/print.dart';

void main() {
  testWidgets('preview is one tap away and preserves settings without rebuilding', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int loadCount = 0;
    PrintJobConfiguration? loadedConfiguration;

    await tester.pumpWidget(
      MaterialApp(
        home: PrintConfigurationScreen(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
          previewDocumentLoader: (PrintJobConfiguration configuration) async {
            loadCount += 1;
            loadedConfiguration = configuration;
            return _document(configuration);
          },
          previewBuilder: (
            BuildContext context,
            PrintDocument document,
          ) {
            return const ColoredBox(
              color: Colors.white,
              child: Center(child: Text('Current PDF bytes')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder widthField = find.byKey(
      const ValueKey<String>('photo-width-millimetres'),
    );
    await _scrollTo(tester, widthField);
    await tester.enterText(widthField, '40');
    await tester.pump();

    final Finder reviewButton = find.byKey(const Key('review-print-job'));
    await _scrollTo(tester, reviewButton);
    expect(reviewButton, findsOneWidget);

    await tester.tap(find.byKey(const Key('preview-view-tab')));
    await tester.pumpAndSettle();

    expect(loadCount, 1);
    expect(loadedConfiguration?.photoWidth.inMillimetres, 40);
    expect(find.text('Current PDF bytes'), findsOneWidget);
    expect(find.byKey(const Key('zoomable-pdf-viewport')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-view-tab')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, widthField);
    final EditableText widthEditable = tester.widget<EditableText>(
      find.descendant(of: widthField, matching: find.byType(EditableText)),
    );
    expect(widthEditable.controller.text, '40');

    await tester.tap(find.byKey(const Key('preview-view-tab')));
    await tester.pumpAndSettle();
    expect(loadCount, 1, reason: 'unchanged settings should reuse the current PDF');
  });

  testWidgets('invalid settings keep preview reachable but do not show stale PDF', (
    WidgetTester tester,
  ) async {
    int loadCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PrintConfigurationScreen(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
          previewDocumentLoader: (PrintJobConfiguration configuration) async {
            loadCount += 1;
            return _document(configuration);
          },
          previewBuilder: (
            BuildContext context,
            PrintDocument document,
          ) {
            return const Text('Should not appear');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder widthField = find.byKey(
      const ValueKey<String>('photo-width-millimetres'),
    );
    await _scrollTo(tester, widthField);
    await tester.enterText(widthField, '0');
    await tester.pump();

    await tester.tap(find.byKey(const Key('preview-view-tab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('step-one-preview-unavailable')), findsOneWidget);
    expect(find.text('Should not appear'), findsNothing);
    expect(loadCount, 0);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    320,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

SelectedImage _image() {
  return SelectedImage(
    bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAACMAAAAtCAIAAACrsUV+AAAARElEQVR42u3V'
      'sREAEBREwc+oQyXKEQkUqAwVaUFCtK+Bnbnk0m4tvpTjVyQSiUR6VRm9Wo9E'
      'IpFIl68Ra1qPRCKRSHcdIZ4DvGdT4rYAAAAASUVORK5CYII=',
    ),
    displayName: 'synthetic.png',
  );
}

PrintDocument _document(PrintJobConfiguration configuration) {
  return PrintDocument(
    bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
    filename: 'photo-cut-${configuration.photoWidth.inMillimetres.round()}mm.pdf',
    pageWidth: configuration.paperSize.width,
    pageHeight: configuration.paperSize.height,
  );
}

final class _FakeImageProcessor implements ImageProcessor {
  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async {
    return SourceImageSize(widthPixels: 400, heightPixels: 200);
  }

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(
      bytes: request.sourceBytes,
      size: SourceImageSize(widthPixels: 400, heightPixels: 200),
    );
  }
}
