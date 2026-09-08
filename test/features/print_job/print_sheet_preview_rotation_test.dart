import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  testWidgets('sheet preview keeps image mounted when photo rotation changes', (
    WidgetTester tester,
  ) async {
    bool rotated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  Expanded(
                    child: PrintSheetPreview(
                      plan: _plan(rotated: rotated),
                      configuration: _configuration(),
                      errorMessage: null,
                    ),
                  ),
                  TextButton(
                    key: const Key('toggle-rotation'),
                    onPressed: () => setState(() => rotated = !rotated),
                    child: const Text('rotate'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(RotatedBox), findsNothing);

    await tester.tap(find.byKey(const Key('toggle-rotation')));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(RotatedBox), findsOneWidget);
  });
}

SheetPlan _plan({required bool rotated}) {
  return SheetPlan(
    paperSize: PaperSize.a4,
    pageOrientation: PageOrientation.portrait,
    pageWidth: PhysicalLength.millimetres(210),
    pageHeight: PhysicalLength.millimetres(297),
    photoRotated: rotated,
    columns: 1,
    rows: 1,
    placements: <PlacedPhoto>[
      PlacedPhoto(
        copyIndex: 0,
        pageIndex: 0,
        left: PhysicalLength.millimetres(20),
        top: PhysicalLength.millimetres(20),
        width: PhysicalLength.millimetres(rotated ? 45 : 35),
        height: PhysicalLength.millimetres(rotated ? 35 : 45),
      ),
    ],
  );
}

PrintJobConfiguration _configuration() {
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
    copyCount: 1,
    margin: PhysicalLength.millimetres(8),
    gap: PhysicalLength.millimetres(2),
    showCutMarks: false,
    fitMode: ImageFitMode.cropToFill,
    colorMode: ImageColorMode.color,
    focus: NormalizedPoint.center,
    cropRect: NormalizedCropRect.full,
    sourceSize: SourceImageSize(widthPixels: 400, heightPixels: 200),
  );
}
