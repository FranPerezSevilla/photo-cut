import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  testWidgets(
    'framing opens a dedicated focus mode before drag updates focus',
    (WidgetTester tester) async {
      NormalizedPoint focus = NormalizedPoint.center;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Center(
                  child: SizedBox(
                    width: 320,
                    child: VisualFramingEditor(
                      configuration: _configuration(focus: focus),
                      onFocusChanged: (NormalizedPoint next) {
                        setState(() => focus = next);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('visual-framing-editor')), findsNothing);
      expect(find.byKey(const Key('open-framing-focus')), findsOneWidget);

      await tester.tap(find.byKey(const Key('open-framing-focus')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('framing-focus-screen')), findsOneWidget);
      expect(find.byKey(const Key('visual-framing-editor')), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('visual-framing-editor')),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();

      expect(focus.x, lessThan(0.5));
      expect(focus.y, 0.5);
      expect(find.byKey(const Key('center-framing')), findsOneWidget);

      await tester.tap(find.byKey(const Key('center-framing')));
      await tester.pumpAndSettle();
      expect(focus, NormalizedPoint.center);
    },
  );

  testWidgets(
    'fill preview and focused editor keep independent image sessions',
    (WidgetTester tester) async {
      NormalizedPoint focus = NormalizedPoint.center;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Center(
                  child: SizedBox(
                    width: 320,
                    child: VisualFramingEditor(
                      configuration: _configuration(focus: focus),
                      onFocusChanged: (NormalizedPoint next) {
                        setState(() => focus = next);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      MemoryImage previewProvider() {
        final Finder previewImage = find.descendant(
          of: find.byKey(const Key('visual-framing-preview')),
          matching: find.byType(Image),
        );
        expect(previewImage, findsOneWidget);
        return tester.widget<Image>(previewImage).image as MemoryImage;
      }

      MemoryImage currentPreview = previewProvider();
      expect(currentPreview.bytes, isNotEmpty);

      for (int attempt = 0; attempt < 2; attempt += 1) {
        final MemoryImage inlineBefore = currentPreview;
        await tester.tap(find.byKey(const Key('open-framing-focus')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('framing-focus-screen')), findsOneWidget);
        final Finder focusedImage = find.descendant(
          of: find.byKey(const Key('visual-framing-editor')),
          matching: find.byType(Image),
        );
        expect(focusedImage, findsOneWidget);
        final MemoryImage focusedProvider =
            tester.widget<Image>(focusedImage).image as MemoryImage;
        expect(focusedProvider.bytes, isNotEmpty);
        expect(
          identical(focusedProvider.bytes, inlineBefore.bytes),
          isFalse,
        );

        await tester.tap(find.text('Guardar encuadre'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('framing-focus-screen')), findsNothing);

        currentPreview = previewProvider();
        expect(currentPreview.bytes, isNotEmpty);
        expect(identical(currentPreview.bytes, inlineBefore.bytes), isFalse);
      }
    },
  );

  testWidgets('fit-inside stays static and does not offer framing adjustment', (
    WidgetTester tester,
  ) async {
    int updates = 0;
    final PrintJobConfiguration configuration = _configuration(
      focus: NormalizedPoint.center,
      fitMode: ImageFitMode.fitInside,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: VisualFramingEditor(
                configuration: configuration,
                onFocusChanged: (NormalizedPoint next) {
                  updates += 1;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-framing-focus')), findsNothing);
    expect(
      find.text('La foto completa queda dentro del marco.'),
      findsOneWidget,
    );
    expect(updates, 0);
  });
}

PrintJobConfiguration _configuration({
  required NormalizedPoint focus,
  ImageFitMode fitMode = ImageFitMode.cropToFill,
}) {
  return PrintJobConfiguration(
    image: SelectedImage(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAACMAAAAtCAIAAACrsUV+AAAARElEQVR42u3V'
        'sREAEBREwc+oQyXKEQkUqAwVaUFCtK+Bnbnk0m4tvpTjVyQSiUR6VRm9Wo9E'
        'IpFIl68Ra1qPRCKRSHcdIZ4DvGdT4rYAAAAASUVORK5CYII=',
      ),
      displayName: 'synthetic.png',
    ),
    photoWidth: PhysicalLength.millimetres(35),
    photoHeight: PhysicalLength.millimetres(45),
    paperSize: PaperSize.a4,
    copyCount: 8,
    margin: PhysicalLength.millimetres(8),
    gap: PhysicalLength.millimetres(2),
    showCutMarks: true,
    fitMode: fitMode,
    colorMode: ImageColorMode.color,
    focus: focus,
    cropRect: NormalizedCropRect.full,
    sourceSize: SourceImageSize(widthPixels: 400, heightPixels: 200),
  );
}
