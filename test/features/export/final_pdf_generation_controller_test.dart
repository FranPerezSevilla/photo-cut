import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/entitlement/entitlement.dart';
import 'package:photo_cut/features/export/export.dart';

void main() {
  test('successful final PDF consumes free use after generation succeeds', () async {
    final _FakeEntitlementStore store = _FakeEntitlementStore();
    final FinalPdfGenerationController controller =
        FinalPdfGenerationController(store: store);

    bool generated = false;
    final FinalPdfGenerationResult<String> result =
        await controller.generate<String>(() async {
      generated = true;
      return 'final.pdf';
    });

    expect(generated, isTrue);
    expect(result.status, FinalPdfGenerationStatus.generated);
    expect(result.value, 'final.pdf');
    expect(store.state.freeFinalPdfConsumed, isTrue);
    expect(store.writeCount, 1);
  });

  test('failed final PDF does not consume free use', () async {
    final _FakeEntitlementStore store = _FakeEntitlementStore();
    final FinalPdfGenerationController controller =
        FinalPdfGenerationController(store: store);

    final FinalPdfGenerationResult<String> result =
        await controller.generate<String>(() async {
      throw StateError('synthetic PDF failure');
    });

    expect(result.status, FinalPdfGenerationStatus.failed);
    expect(store.state.freeFinalPdfConsumed, isFalse);
    expect(store.writeCount, 0);
  });

  test('exhausted free use blocks before final PDF generation starts', () async {
    final _FakeEntitlementStore store = _FakeEntitlementStore(
      const EntitlementState(freeFinalPdfConsumed: true),
    );
    final FinalPdfGenerationController controller =
        FinalPdfGenerationController(store: store);

    bool generationStarted = false;
    final FinalPdfGenerationResult<String> result =
        await controller.generate<String>(() async {
      generationStarted = true;
      return 'should-not-exist.pdf';
    });

    expect(result.status, FinalPdfGenerationStatus.requiresPurchase);
    expect(generationStarted, isFalse);
  });

  test('lifetime entitlement can generate repeatedly', () async {
    final _FakeEntitlementStore store = _FakeEntitlementStore(
      const EntitlementState(
        freeFinalPdfConsumed: true,
        lifetimeUnlocked: true,
      ),
    );
    final FinalPdfGenerationController controller =
        FinalPdfGenerationController(store: store);

    expect(
      (await controller.generate<String>(() async => 'one.pdf')).status,
      FinalPdfGenerationStatus.generated,
    );
    expect(
      (await controller.generate<String>(() async => 'two.pdf')).status,
      FinalPdfGenerationStatus.generated,
    );
    expect(store.writeCount, 0);
  });

  test('a fresh local store documents reinstall assumption', () async {
    final _FakeEntitlementStore previousInstall = _FakeEntitlementStore(
      const EntitlementState(freeFinalPdfConsumed: true),
    );
    final _FakeEntitlementStore freshInstall = _FakeEntitlementStore();

    expect((await previousInstall.read()).canGenerateFinalPdf, isFalse);
    expect((await freshInstall.read()).canGenerateFinalPdf, isTrue);
  });
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
