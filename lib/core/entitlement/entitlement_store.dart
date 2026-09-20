import 'package:photo_cut/core/entitlement/entitlement_state.dart';

/// Persistence boundary for Photo Cut's minimal commercial state.
///
/// Store purchase APIs are deliberately kept outside this interface.
abstract interface class EntitlementStore {
  Future<EntitlementState> read();

  Future<void> write(EntitlementState state);
}
