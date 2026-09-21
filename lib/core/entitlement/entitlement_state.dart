/// Store-independent commercial state for Photo Cut.
///
/// A fresh installation may generate one final PDF for free. The Step 1 preview
/// is outside this model. A lifetime unlock bypasses the free-use allowance.
final class EntitlementState {
  const EntitlementState({
    this.freeFinalPdfConsumed = false,
    this.lifetimeUnlocked = false,
  });

  final bool freeFinalPdfConsumed;
  final bool lifetimeUnlocked;

  bool get canGenerateFinalPdf =>
      lifetimeUnlocked || !freeFinalPdfConsumed;

  int get remainingFreeFinalPdfs =>
      lifetimeUnlocked ? 0 : (freeFinalPdfConsumed ? 0 : 1);

  EntitlementState consumeSuccessfulFinalPdf() {
    if (lifetimeUnlocked || freeFinalPdfConsumed) {
      return this;
    }
    return EntitlementState(
      freeFinalPdfConsumed: true,
      lifetimeUnlocked: lifetimeUnlocked,
    );
  }

  EntitlementState withLifetimeUnlocked(bool unlocked) {
    if (unlocked == lifetimeUnlocked) {
      return this;
    }
    return EntitlementState(
      freeFinalPdfConsumed: freeFinalPdfConsumed,
      lifetimeUnlocked: unlocked,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EntitlementState &&
        other.freeFinalPdfConsumed == freeFinalPdfConsumed &&
        other.lifetimeUnlocked == lifetimeUnlocked;
  }

  @override
  int get hashCode => Object.hash(freeFinalPdfConsumed, lifetimeUnlocked);
}
