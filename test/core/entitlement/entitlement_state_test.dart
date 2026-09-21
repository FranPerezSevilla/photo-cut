import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/entitlement/entitlement.dart';

void main() {
  test('fresh install has exactly one free final PDF', () {
    const EntitlementState state = EntitlementState();

    expect(state.canGenerateFinalPdf, isTrue);
    expect(state.remainingFreeFinalPdfs, 1);
  });

  test('successful free final PDF consumes the allowance exactly once', () {
    const EntitlementState fresh = EntitlementState();

    final EntitlementState consumed =
        fresh.consumeSuccessfulFinalPdf();

    expect(consumed.freeFinalPdfConsumed, isTrue);
    expect(consumed.canGenerateFinalPdf, isFalse);
    expect(consumed.consumeSuccessfulFinalPdf(), same(consumed));
  });

  test('lifetime entitlement bypasses consumed allowance', () {
    const EntitlementState consumed = EntitlementState(
      freeFinalPdfConsumed: true,
    );

    final EntitlementState unlocked =
        consumed.withLifetimeUnlocked(true);

    expect(unlocked.canGenerateFinalPdf, isTrue);
    expect(unlocked.freeFinalPdfConsumed, isTrue);
  });
}
