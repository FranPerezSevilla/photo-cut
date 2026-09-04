import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/physical_length.dart';
import 'package:photo_cut/features/pdf_spike/pdf_spike.dart';
import 'package:photo_cut/platform/print/print.dart';

void main() {
  testWidgets(
    'shows the deterministic preview and routes actions via gateway',
    (WidgetTester tester) async {
      final PrintDocument document = _document();
      final _FakePrintGateway gateway = _FakePrintGateway();

      await tester.pumpWidget(
        MaterialApp(
          home: PdfSpikeScreen(
            documentLoader: () async => document,
            printGateway: gateway,
            previewBuilder:
                (BuildContext context, PrintDocument previewDocument) {
                  return const Center(child: Text('Synthetic PDF preview'));
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prueba de PDF'), findsOneWidget);
      expect(find.text('Synthetic PDF preview'), findsOneWidget);
      expect(find.textContaining('8 copias de 35 × 45 mm'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pdf-spike-share')));
      await tester.pumpAndSettle();
      expect(gateway.shared, same(document));
      expect(find.text('Documento preparado para compartir.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pdf-spike-print')));
      await tester.pumpAndSettle();
      expect(gateway.printed, same(document));
      expect(
        find.text('Documento enviado al sistema de impresión.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('reports cancellation without treating it as an error', (
    WidgetTester tester,
  ) async {
    final _FakePrintGateway gateway = _FakePrintGateway(printResult: false);

    await tester.pumpWidget(
      MaterialApp(
        home: PdfSpikeScreen(
          documentLoader: () async => _document(),
          printGateway: gateway,
          previewBuilder: (BuildContext context, PrintDocument document) {
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pdf-spike-print')));
    await tester.pumpAndSettle();

    expect(find.text('Impresión cancelada.'), findsOneWidget);
  });

  testWidgets('offers retry when sample generation fails', (
    WidgetTester tester,
  ) async {
    int attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PdfSpikeScreen(
          documentLoader: () async {
            attempts += 1;
            if (attempts == 1) {
              throw StateError('synthetic failure');
            }
            return _document();
          },
          printGateway: _FakePrintGateway(),
          previewBuilder: (BuildContext context, PrintDocument document) {
            return const Center(child: Text('Recovered preview'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo generar el PDF de ejemplo.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Recovered preview'), findsOneWidget);
  });
}

PrintDocument _document() {
  return PrintDocument(
    bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
    filename: 'sample.pdf',
    pageWidth: PhysicalLength.millimetres(297),
    pageHeight: PhysicalLength.millimetres(210),
  );
}

final class _FakePrintGateway implements PrintGateway {
  _FakePrintGateway({this.printResult = true});

  final bool printResult;
  PrintDocument? printed;
  PrintDocument? shared;

  @override
  Future<bool> printPdf(PrintDocument document) async {
    printed = document;
    return printResult;
  }

  @override
  Future<bool> sharePdf(PrintDocument document) async {
    shared = document;
    return true;
  }
}
