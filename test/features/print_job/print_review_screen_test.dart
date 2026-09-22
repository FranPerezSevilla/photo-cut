import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/entitlement/entitlement.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/export/export.dart';
import 'package:photo_cut/features/paywall/paywall.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/print/print.dart';
import 'package:photo_cut/platform/purchase/purchase.dart';

void main() {
  testWidgets('reviews one immutable document and routes both final actions', (
    WidgetTester tester,
  ) async {
    final PrintDocument document = _document();
    final _FakePrintGateway gateway = _FakePrintGateway();
    final _FakeEntitlementStore entitlementStore = _FakeEntitlementStore();
    PrintDocument? previewed;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: PrintReviewScreen(
          configuration: _configuration(),
          documentLoader: () async => document,
          printGateway: gateway,
          finalPdfGenerationController: FinalPdfGenerationController(
            store: entitlementStore,
          ),
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
    expect(entitlementStore.state.freeFinalPdfConsumed, isTrue);
    expect(entitlementStore.writeCount, 1);
    expect(find.text('Paso 2 de 2 · Revisa el PDF final'), findsOneWidget);
    expect(find.text('35 × 45 mm · 8 copias · A4'), findsOneWidget);
    expect(find.text('Rellenar · B/N · Con marcas de corte'), findsOneWidget);
    expect(find.text('Abrir impresión de Android'), findsOneWidget);
    expect(find.textContaining(document.filename), findsOneWidget);

    await tester.tap(find.byKey(const Key('share-final-pdf')));
    await tester.pumpAndSettle();
    expect(gateway.shared, same(document));
    expect(entitlementStore.writeCount, 1);
    expect(find.text('PDF preparado para compartir.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-native-print')));
    await tester.pumpAndSettle();
    expect(gateway.printed, same(document));
    expect(entitlementStore.writeCount, 1);
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
          finalPdfGenerationController: FinalPdfGenerationController(
            store: _FakeEntitlementStore(),
          ),
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
          finalPdfGenerationController: FinalPdfGenerationController(
            store: _FakeEntitlementStore(),
          ),
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

  testWidgets('exhausted free use blocks before final PDF generation', (
    WidgetTester tester,
  ) async {
    int generationCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PrintReviewScreen(
          configuration: _configuration(),
          documentLoader: () async {
            generationCalls += 1;
            return _document();
          },
          printGateway: _FakePrintGateway(),
          finalPdfGenerationController: FinalPdfGenerationController(
            store: _FakeEntitlementStore(
              const EntitlementState(freeFinalPdfConsumed: true),
            ),
          ),
          previewBuilder: (BuildContext context, PrintDocument document) {
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(generationCalls, 0);
    expect(
      find.byKey(const Key('final-pdf-purchase-required')),
      findsOneWidget,
    );
    expect(find.text('Ya has usado tu PDF gratuito'), findsOneWidget);
    expect(find.byKey(const Key('share-final-pdf')), findsNothing);
    expect(find.byKey(const Key('open-native-print')), findsNothing);
  });


  testWidgets('lifetime purchase unlocks and retries final PDF generation', (
    WidgetTester tester,
  ) async {
    int generationCalls = 0;
    final _FakeEntitlementStore entitlementStore = _FakeEntitlementStore(
      const EntitlementState(freeFinalPdfConsumed: true),
    );
    final FinalPdfGenerationController generationController =
        FinalPdfGenerationController(store: entitlementStore);
    final _FakePurchaseGateway purchaseGateway = _FakePurchaseGateway(
      autoPurchase: true,
    );
    final LifetimePurchaseController purchaseController =
        LifetimePurchaseController(
          gateway: purchaseGateway,
          entitlementWriter: generationController.setLifetimeUnlocked,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: PrintReviewScreen(
          configuration: _configuration(),
          documentLoader: () async {
            generationCalls += 1;
            return _document();
          },
          printGateway: _FakePrintGateway(),
          finalPdfGenerationController: generationController,
          lifetimePurchaseController: purchaseController,
          previewBuilder: (BuildContext context, PrintDocument document) {
            return const Center(child: Text('Unlocked final PDF'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(generationCalls, 0);
    expect(find.byKey(const Key('lifetime-paywall')), findsOneWidget);
    expect(find.text('Pago único · Sin suscripción'), findsOneWidget);

    await tester.tap(find.byKey(const Key('buy-lifetime')));
    await tester.pumpAndSettle();

    expect(purchaseGateway.buyCalls, 1);
    expect(purchaseGateway.completeCalls, 1);
    expect(entitlementStore.state.lifetimeUnlocked, isTrue);
    expect(generationCalls, 1);
    expect(find.text('Unlocked final PDF'), findsOneWidget);
    expect(find.byKey(const Key('share-final-pdf')), findsOneWidget);
    expect(find.byKey(const Key('open-native-print')), findsOneWidget);
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


final class _FakeEntitlementStore implements EntitlementStore {
  _FakeEntitlementStore([this.state = const EntitlementState()]);

  EntitlementState state;
  int writeCount = 0;

  @override
  Future<EntitlementState> read() async => state;

  @override
  Future<void> write(EntitlementState state) async {
    this.state = state;
    writeCount += 1;
  }
}


final class _FakePurchaseGateway implements PurchaseGateway {
  _FakePurchaseGateway({this.autoPurchase = false});

  final bool autoPurchase;
  final StreamController<PurchaseUpdate> _updates =
      StreamController<PurchaseUpdate>.broadcast();

  int buyCalls = 0;
  int completeCalls = 0;

  @override
  Stream<PurchaseUpdate> get updates => _updates.stream;

  @override
  Future<PurchaseProductResult> loadProduct(String productId) async {
    return PurchaseProductResult(
      storeAvailable: true,
      product: PurchaseProduct(
        id: productId,
        title: 'Photo Cut Lifetime',
        description: 'One-time unlock',
        price: '3,99 €',
        platformPayload: Object(),
      ),
    );
  }

  @override
  Future<void> buyNonConsumable(PurchaseProduct product) async {
    buyCalls += 1;
    if (autoPurchase) {
      _updates.add(
        const PurchaseUpdate(
          productId: 'photo_cut_lifetime',
          status: PurchaseUpdateStatus.purchased,
          needsCompletion: true,
          platformPayload: 'opaque',
        ),
      );
    }
  }

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> completePurchase(PurchaseUpdate update) async {
    completeCalls += 1;
  }
}
