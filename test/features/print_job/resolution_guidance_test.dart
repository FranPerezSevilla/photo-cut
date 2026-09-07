import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  testWidgets('shows compact guidance when resolution is sufficient', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResolutionGuidance(
            configuration: _configuration(sourcePixels: 300, outputInches: 1),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('resolution-guidance-ok')), findsOneWidget);
    expect(find.textContaining('300 ppp'), findsOneWidget);
    expect(find.byKey(const Key('resolution-warning')), findsNothing);
  });

  testWidgets('warns below 200 DPI without disabling the rest of the UI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              ResolutionGuidance(
                configuration: _configuration(
                  sourcePixels: 180,
                  outputInches: 1,
                ),
              ),
              const FilledButton(onPressed: _noop, child: Text('Continuar')),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('resolution-warning')), findsOneWidget);
    expect(find.text('Resolución justa'), findsOneWidget);
    expect(find.textContaining('180 ppp'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('labels very low resolution separately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResolutionGuidance(
            configuration: _configuration(sourcePixels: 100, outputInches: 1),
          ),
        ),
      ),
    );

    expect(find.text('Resolución baja'), findsOneWidget);
    expect(find.textContaining('100 ppp'), findsOneWidget);
  });
}

void _noop() {}

PrintJobConfiguration _configuration({
  required int sourcePixels,
  required double outputInches,
}) {
  return PrintJobConfiguration(
    image: SelectedImage(
      bytes: Uint8List.fromList(<int>[1]),
      displayName: 'synthetic.jpg',
    ),
    photoWidth: PhysicalLength.inches(outputInches),
    photoHeight: PhysicalLength.inches(outputInches),
    paperSize: PaperSize.a4,
    copyCount: 1,
    margin: PhysicalLength.millimetres(8),
    gap: PhysicalLength.millimetres(2),
    showCutMarks: false,
    fitMode: ImageFitMode.cropToFill,
    colorMode: ImageColorMode.color,
    focus: NormalizedPoint.center,
    cropRect: NormalizedCropRect.full,
    sourceSize: SourceImageSize(
      widthPixels: sourcePixels,
      heightPixels: sourcePixels,
    ),
  );
}
