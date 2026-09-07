import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  testWidgets('primary controls expose contextual help in Step 1', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpScreen(tester);

    for (final String key in <String>[
      'help-fitMode',
      'help-framing',
      'help-colorMode',
      'help-unit',
      'help-width',
      'help-height',
      'help-paper',
      'help-copies',
    ]) {
      expect(
        find.byKey(ValueKey<String>(key), skipOffstage: false),
        findsOneWidget,
        reason: key,
      );
    }

    final Finder fitHelp = find.byKey(const Key('help-fitMode'));
    await tester.tap(fitHelp);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('configuration-help-sheet')), findsOneWidget);
    expect(find.text('Rellenar o encajar'), findsOneWidget);
    expect(find.text('Qué hace'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
  });

  testWidgets('advanced options start collapsed and expose their own help', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester);

    final Finder advanced = find.byKey(const Key('advanced-options'));
    await _scrollTo(tester, advanced);
    final ExpansionTile tile = tester.widget<ExpansionTile>(advanced);
    expect(tile.initiallyExpanded, isFalse);

    await tester.tap(find.text('Opciones avanzadas'));
    await tester.pumpAndSettle();

    for (final String key in <String>[
      'help-margin',
      'help-gap',
      'help-cutMarks',
    ]) {
      final Finder finder = find.byKey(ValueKey<String>(key));
      await _scrollTo(tester, finder);
      expect(finder, findsOneWidget, reason: key);
    }
  });

  testWidgets('ignoring advanced options preserves useful defaults', (
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

    final Finder review = find.byKey(const Key('review-print-job'));
    await _scrollTo(tester, review);
    await tester.tap(review);
    await tester.pump();

    expect(reviewed, isNotNull);
    expect(reviewed!.margin.inMillimetres, 8);
    expect(reviewed!.gap.inMillimetres, 2);
    expect(reviewed!.showCutMarks, isTrue);
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PrintConfigurationScreen(
        image: _image(),
        imageProcessor: _FakeImageProcessor(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
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
