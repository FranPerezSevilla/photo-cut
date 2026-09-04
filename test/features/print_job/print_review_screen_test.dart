import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/print/print.dart';

void main() {
  testWidgets('reviews one immutable document and routes both final actions', (
    WidgetTester tester,
  ) async {
    final PrintDocument document = _document();
    final _FakePrintGateway gateway = _FakePrintGateway();
    PrintDocument? previewed;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: PrintReviewScreen(
          configuration: _configuration(),
          documentLoader: () async => document,
          printGateway: gateway,
          previewBuilder:
              (BuildContext context, PrintDocument previewDocument) {
                previewed = previewDocument;
                return const Center(child: Text('Vista previa final'));
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(previewed, same(document));
    expect(find.text('Paso 2 de 2 · Revisa el PDF final'), findsOneWidget);
    expect(find.text('35 × 45 mm · 8 copias · A4'), findsOneWidget);
    expect(
      find.text('Rellenar · Blanco y negro · Con marcas de corte'),
      findsOneWidget,
    );
    expect(find.text('Abrir impresión de Android'), findsOneWidget);
    expect(find.textContaining(document.filename), findsOneWidget);

    await tester.tap(find.byKey(const Key('share-final-pdf')));
    await tester.pumpAndSettle();
    expect(gateway.shared, same(document));
    expect(find.text('PDF preparado para compartir.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-native-print')));
    await tester.pumpAndSettle();
    expect(gateway.printed, same(document));
    expect(
      find.text('Has vuelto de la impresión del sistema.'),
      findsOneWidget,
    );
  });

  testWidgets('action cancellation stays recoverable on the review screen', (
    WidgetTester tester,
  ) async {
    final _FakePrintGateway gateway = _FakePrintGateway(
      shareResult: false,
      printResult: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PrintReviewScreen(
          configuration: _configuration(),
          documentLoader: () async => _document(),
          printGateway: gateway,
          previewBuilder: (BuildContext context, PrintDocument document) {
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('share-final-pdf')));
    await tester.pumpAndSettle();
    expect(find.text('Compartir cancelado.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-native-print')));
    await tester.pumpAndSettle();
    expect(find.text('Impresión cancelada.'), findsOneWidget);
    expect(find.byKey(const Key('edit-print-job')), findsOneWidget);
  });

  testWidgets('document generation can be retried without losing settings', (
    WidgetTester tester,
  ) async {
    int attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PrintReviewScreen(
          configuration: _configuration(),
          documentLoader: () async {
            attempts += 1;
            if (attempts == 1) {
              throw StateError('synthetic document failure');
            }
            return _document();
          },
          printGateway: _FakePrintGateway(),
          previewBuilder: (BuildContext context, PrintDocument document) {
            return const Center(child: Text('Recovered final preview'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo preparar el PDF final.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Recovered final preview'), findsOneWidget);
    expect(find.text('35 × 45 mm · 8 copias · A4'), findsOneWidget);
  });
}

PrintDocument _document() {
  return PrintDocument(
    bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
    filename: 'photo-cut-retrato-35x45mm-8copias-a4-bn.pdf',
    pageWidth: PhysicalLength.millimetres(210),
    pageHeight: PhysicalLength.millimetres(297),
  );
}

PrintJobConfiguration _configuration() {
  return PrintJobConfiguration(
    image: SelectedImage(
      bytes: Uint8List.fromList(<int>[1]),
      displayName: 'retrato.jpg',
    ),
    photoWidth: PhysicalLength.millimetres(35),
    photoHeight: PhysicalLength.millimetres(45),
    paperSize: PaperSize.a4,
    copyCount: 8,
    margin: PhysicalLength.millimetres(8),
    gap: PhysicalLength.millimetres(2),
    showCutMarks: true,
    fitMode: ImageFitMode.cropToFill,
    colorMode: ImageColorMode.grayscale,
    focus: NormalizedPoint.center,
    cropRect: NormalizedCropRect.full,
    sourceSize: SourceImageSize(widthPixels: 350, heightPixels: 450),
  );
}

final class _FakePrintGateway implements PrintGateway {
  _FakePrintGateway({this.shareResult = true, this.printResult = true});

  final bool printResult;
  final bool shareResult;
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
    return shareResult;
  }
}
