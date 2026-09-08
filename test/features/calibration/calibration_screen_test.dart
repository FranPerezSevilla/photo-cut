import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/physical_length.dart';
import 'package:photo_cut/features/calibration/calibration.dart';
import 'package:photo_cut/platform/print/print.dart';

void main() {
  testWidgets('explains scale verification without implying app calibration', (
    WidgetTester tester,
  ) async {
    final _FakePrintGateway gateway = _FakePrintGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: CalibrationScreen(
          generateDocument: _result,
          printGateway: gateway,
          previewBuilder: (BuildContext context, PrintDocument document) {
            return const Center(child: Text('Calibration PDF preview'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calibration PDF preview'), findsOneWidget);
    expect(find.text('Prueba de escala de impresión'), findsOneWidget);
    expect(find.textContaining('ya genera el PDF con medidas físicas exactas'), findsOneWidget);
    expect(find.textContaining('no calibra ni modifica Photo Cut'), findsOneWidget);
    expect(find.textContaining('100 %'), findsOneWidget);
    expect(find.textContaining('Tamaño real'), findsOneWidget);
    expect(find.textContaining('Ajustar a página'), findsOneWidget);
    expect(find.textContaining('no puede controlar el escalado'), findsOneWidget);
    expect(find.textContaining('50 × 50 mm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('print-calibration')));
    await tester.pumpAndSettle();

    expect(gateway.printCalls, 1);
    expect(gateway.lastDocument?.filename, 'photo-cut-calibration-50mm.pdf');
    expect(find.text('Solicitud de impresión enviada.'), findsOneWidget);
  });
}

Future<CalibrationPdfResult> _result() async {
  return CalibrationPdfResult(
    document: PrintDocument(
      bytes: Uint8List.fromList(<int>[1]),
      filename: 'photo-cut-calibration-50mm.pdf',
      pageWidth: PhysicalLength.millimetres(210),
      pageHeight: PhysicalLength.millimetres(297),
    ),
    squareWidthPoints: PhysicalLength.millimetres(50).inPdfPoints,
    squareHeightPoints: PhysicalLength.millimetres(50).inPdfPoints,
  );
}

final class _FakePrintGateway implements PrintGateway {
  int printCalls = 0;
  PrintDocument? lastDocument;

  @override
  Future<bool> printPdf(PrintDocument document) async {
    printCalls += 1;
    lastDocument = document;
    return true;
  }

  @override
  Future<bool> sharePdf(PrintDocument document) async => true;
}
