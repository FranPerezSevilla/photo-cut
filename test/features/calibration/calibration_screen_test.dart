import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/calibration/calibration.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';
import 'package:photo_cut/platform/print/print.dart';

void main() {
  testWidgets('shows free actual-size guidance and the 50 mm preview', (
    WidgetTester tester,
  ) async {
    final _FakePrintGateway gateway = _FakePrintGateway();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: CalibrationScreen(
          documentLoader: _resultFor,
          printGateway: gateway,
          previewBuilder: (
            BuildContext context,
            PrintDocument document,
          ) {
            return const Center(child: Text('Vista de calibración'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calibrar impresión'), findsOneWidget);
    expect(find.textContaining('50 × 50 mm'), findsOneWidget);
    expect(find.byKey(const Key('calibration-before-purchase')), findsOneWidget);
    expect(find.byKey(const Key('actual-size-guidance')), findsOneWidget);
    expect(find.byKey(const Key('no-fit-to-page-guidance')), findsOneWidget);
    expect(find.byKey(const Key('printer-scaling-caveat')), findsOneWidget);
    expect(find.text('Vista de calibración'), findsOneWidget);
    expect(find.text('Abrir impresión de Android'), findsOneWidget);
  });

  testWidgets('shares and prints the same generated calibration document', (
    WidgetTester tester,
  ) async {
    final _FakePrintGateway gateway = _FakePrintGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: CalibrationScreen(
          documentLoader: _resultFor,
          printGateway: gateway,
          previewBuilder: (
            BuildContext context,
            PrintDocument document,
          ) {
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder share = find.byKey(const Key('share-calibration-pdf'));
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.pumpAndSettle();

    final Finder print = find.byKey(const Key('print-calibration-pdf'));
    await tester.ensureVisible(print);
    await tester.tap(print);
    await tester.pumpAndSettle();

    expect(gateway.shared, isNotNull);
    expect(gateway.printed, same(gateway.shared));
    expect(gateway.printed?.filename, contains('calibracion-a4-50mm'));
  });

  testWidgets('paper selection regenerates a matching calibration document', (
    WidgetTester tester,
  ) async {
    final List<PaperSize> loadedPapers = <PaperSize>[];
    await tester.pumpWidget(
      MaterialApp(
        home: CalibrationScreen(
          documentLoader: (PaperSize paper) async {
            loadedPapers.add(paper);
            return _resultFor(paper);
          },
          printGateway: _FakePrintGateway(),
          previewBuilder: (
            BuildContext context,
            PrintDocument document,
          ) {
            return Text(document.filename);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calibration-paper-size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foto · 10 × 15 cm').last);
    await tester.pumpAndSettle();

    expect(loadedPapers, <PaperSize>[PaperSize.a4, PaperSize.photo10x15]);
    expect(find.textContaining('photo-10x15-50mm.pdf'), findsOneWidget);
  });
}

Future<CalibrationPdfResult> _resultFor(PaperSize paper) async {
  return CalibrationPdfResult(
    document: PrintDocument(
      bytes: Uint8List.fromList(<int>[37, 80, 68, 70, 45]),
      filename: 'photo-cut-calibracion-${paper.id}-50mm.pdf',
      pageWidth: paper.width,
      pageHeight: paper.height,
    ),
    square: CalibrationSquareGeometry(
      leftPoints: 10,
      topPoints: 10,
      widthPoints: PhysicalLength.millimetres(50).inPdfPoints,
      heightPoints: PhysicalLength.millimetres(50).inPdfPoints,
    ),
  );
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
