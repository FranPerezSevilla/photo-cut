import 'package:photo_cut/core/entitlement/entitlement.dart';

enum FinalPdfGenerationStatus { generated, failed, requiresPurchase }

final class FinalPdfGenerationResult<T> {
  const FinalPdfGenerationResult._({
    required this.status,
    this.value,
    this.error,
  });

  const FinalPdfGenerationResult.generated(T value)
    : this._(status: FinalPdfGenerationStatus.generated, value: value);

  const FinalPdfGenerationResult.failed(Object error)
    : this._(status: FinalPdfGenerationStatus.failed, error: error);

  const FinalPdfGenerationResult.requiresPurchase()
    : this._(status: FinalPdfGenerationStatus.requiresPurchase);

  final FinalPdfGenerationStatus status;
  final T? value;
  final Object? error;
}

/// Enforces the one-free-final-PDF rule around final document generation.
///
/// Step 1 preview generation never goes through this controller. Share and print
/// also stay outside it: once a final PDF exists, the user may review, share and
/// print that already-generated document without spending another use.
final class FinalPdfGenerationController {
  FinalPdfGenerationController({required EntitlementStore store})
    : _store = store;

  final EntitlementStore _store;
  EntitlementState? _state;

  Future<EntitlementState> get state async => _state ??= await _store.read();

  Future<FinalPdfGenerationResult<T>> generate<T>(
    Future<T> Function() buildFinalPdf,
  ) async {
    final EntitlementState current = await state;
    if (!current.canGenerateFinalPdf) {
      return const FinalPdfGenerationResult<T>.requiresPurchase();
    }

    final T document;
    try {
      document = await buildFinalPdf();
    } on Object catch (error) {
      return FinalPdfGenerationResult<T>.failed(error);
    }

    if (!current.lifetimeUnlocked && !current.freeFinalPdfConsumed) {
      final EntitlementState consumed =
          current.consumeSuccessfulFinalPdf();
      _state = consumed;
      try {
        await _store.write(consumed);
      } on Object {
        // The final PDF already exists successfully. Keep the in-memory state
        // consumed rather than misreporting generation as failed.
      }
    }

    return FinalPdfGenerationResult<T>.generated(document);
  }

  /// Used by M4-T02 after a verified purchase or restore.
  Future<void> setLifetimeUnlocked(bool unlocked) async {
    final EntitlementState updated =
        (await state).withLifetimeUnlocked(unlocked);
    _state = updated;
    await _store.write(updated);
  }
}
