import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  testWidgets('renders defaults and an orientation-aware live preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrintConfigurationScreen(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preparar en Photo Cut'), findsOneWidget);
    expect(find.text('Paso 1 de 2 · Configura el documento'), findsOneWidget);
    expect(find.byKey(const Key('source-image-size')), findsOneWidget);
    expect(find.text('Original orientado: 400 × 200 px'), findsOneWidget);
    expect(find.byKey(const Key('layout-page-summary')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('layout-photo-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('layout-photo-7')),
      findsOneWidget,
    );
    expect(find.text('8 copias · 1 página'), findsOneWidget);
  });

  testWidgets('invalid input is accessible and disables review', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrintConfigurationScreen(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
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

    expect(find.text('Introduce una medida mayor que 0.'), findsOneWidget);

    final Finder reviewButton = find.byKey(const Key('review-print-job'));
    await _scrollTo(tester, reviewButton);
    final FilledButton button = tester.widget<FilledButton>(reviewButton);
    expect(button.onPressed, isNull);
  });

  testWidgets('fit and grayscale controls visibly update Photo Cut', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrintConfigurationScreen(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder fitSelector = find.byKey(const Key('fit-mode-selector'));
    await _scrollTo(tester, fitSelector);
    await tester.tap(find.text('Encajar'));
    await tester.pump();

    expect(find.byKey(const Key('crop-focus-x')), findsNothing);
    expect(find.byKey(const Key('crop-focus-y')), findsNothing);
    expect(
      find.text(
        'Muestra la foto completa sin deformarla; pueden quedar bordes blancos.',
      ),
      findsOneWidget,
    );

    final Finder colorSelector = find.byKey(const Key('color-mode-selector'));
    await _scrollTo(tester, colorSelector);
    await tester.tap(find.text('Blanco y negro'));
    await tester.pump();

    await _scrollTo(
      tester,
      find.byKey(const Key('layout-page-summary')),
      delta: -350,
    );
    expect(
      find.byKey(const ValueKey<String>('preview-grayscale-0')),
      findsOneWidget,
    );
  });

  testWidgets('copy count updates the live pagination summary', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrintConfigurationScreen(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder copyField = find.byKey(const Key('copy-count'));
    await _scrollTo(tester, copyField);
    await tester.enterText(copyField, '40');
    await tester.pump();

    await _scrollTo(
      tester,
      find.byKey(const Key('layout-page-summary')),
      delta: -300,
    );
    expect(find.text('Página 1 de 2 · 40 copias'), findsOneWidget);
  });

  testWidgets('valid review emits crop, fit and colour configuration', (
    WidgetTester tester,
  ) async {
    PrintJobConfiguration? reviewed;
    await tester.pumpWidget(
      MaterialApp(
        home: PrintConfigurationScreen(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
          onReview:
              (BuildContext context, PrintJobConfiguration configuration) {
                reviewed = configuration;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('color-mode-selector')));
    await tester.tap(find.text('Blanco y negro'));
    await tester.pump();

    final Finder reviewButton = find.byKey(const Key('review-print-job'));
    await _scrollTo(tester, reviewButton);
    await tester.tap(reviewButton);
    await tester.pump();

    expect(reviewed, isNotNull);
    expect(reviewed?.photoWidth.inMillimetres, 35);
    expect(reviewed?.copyCount, 8);
    expect(reviewed?.colorMode, ImageColorMode.grayscale);
    expect(reviewed?.fitMode, ImageFitMode.cropToFill);
    expect(reviewed?.cropRect, isNot(NormalizedCropRect.full));
    expect(reviewed?.sourceSize?.widthPixels, 400);
  });
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
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

final class _FakeImageProcessor implements ImageProcessor {
  _FakeImageProcessor()
    : size = SourceImageSize(widthPixels: 400, heightPixels: 200);

  final SourceImageSize size;

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async => size;

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(bytes: request.sourceBytes, size: size);
  }
}
