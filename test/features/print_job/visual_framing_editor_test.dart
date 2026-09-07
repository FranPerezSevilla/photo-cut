import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  testWidgets('dragging the image updates the existing normalized focus', (
    WidgetTester tester,
  ) async {
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
                      setState(() {
                        focus = next;
                      });
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

    expect(find.text('Rellenar · recorte activo'), findsOneWidget);
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
  });

  testWidgets('fit-inside is visibly complete and does not drag focus', (
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

    expect(find.text('Encajar · foto completa'), findsOneWidget);
    expect(
      find.text('Encajar muestra la foto completa y no recorta ninguna parte.'),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('visual-framing-editor')),
      const Offset(100, 0),
    );
    await tester.pumpAndSettle();
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
