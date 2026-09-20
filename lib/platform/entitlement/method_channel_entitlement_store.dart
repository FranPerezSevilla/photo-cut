import 'package:flutter/services.dart';
import 'package:photo_cut/core/entitlement/entitlement.dart';

/// Native persistence for Photo Cut's small commercial state.
///
/// Android stores the values in SharedPreferences and iOS in UserDefaults.
/// This is only a local cache; uninstalling the app may clear the free-use
/// marker. Lifetime purchase restoration remains the store's responsibility.
final class MethodChannelEntitlementStore implements EntitlementStore {
  const MethodChannelEntitlementStore({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const String _channelName = 'com.frainzzel.photocut/entitlement';

  final MethodChannel _channel;

  @override
  Future<EntitlementState> read() async {
    final Map<Object?, Object?>? raw =
        await _channel.invokeMapMethod<Object?, Object?>('read');

    return EntitlementState(
      freeFinalPdfConsumed:
          raw?['freeFinalPdfConsumed'] as bool? ?? false,
      lifetimeUnlocked: raw?['lifetimeUnlocked'] as bool? ?? false,
    );
  }

  @override
  Future<void> write(EntitlementState state) {
    return _channel.invokeMethod<void>('write', <String, bool>{
      'freeFinalPdfConsumed': state.freeFinalPdfConsumed,
      'lifetimeUnlocked': state.lifetimeUnlocked,
    });
  }
}
