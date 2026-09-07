import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/print/print.dart';

void main() {
  testWidgets('pinch zoom, pan and fit-page reset stay in viewer state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final TransformationController controller = TransformationController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomablePdfDocumentPreview(
            document: _document(),
            transformationController: controller,
            previewBuilder: (BuildContext context, PrintDocument document) {
              return const ColoredBox(
                color: Colors.white,
                child: Center(child: Text('Synthetic PDF page')),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder viewport = find.byKey(const Key('zoomable-pdf-viewport'));
    final Offset center = tester.getCenter(viewport);
    final TestGesture first = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final TestGesture second = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await first.moveTo(center - const Offset(100, 0));
    await second.moveTo(center + const Offset(100, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    final double zoomedScale = controller.value.getMaxScaleOnAxis();

    await tester.drag(viewport, const Offset(45, 25));
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), closeTo(zoomedScale, 0.001));

    await tester.tap(find.byKey(const Key('fit-page-preview')));
    await tester.pumpAndSettle();

    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, 0.0001));
    expect(controller.value.getTranslation().x, closeTo(0, 0.0001));
    expect(controller.value.getTranslation().y, closeTo(0, 0.0001));
    expect(find.text('100%'), findsOneWidget);
  });
}

PrintDocument _document() {
  return PrintDocument(
    bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
    filename: 'photo-cut-preview.pdf',
    pageWidth: PhysicalLength.millimetres(210),
    pageHeight: PhysicalLength.millimetres(297),
  );
}
