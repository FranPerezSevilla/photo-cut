import 'package:flutter/services.dart';
import 'package:photo_cut/core/entitlement/entitlement.dart';

/// Native persistence for Photo Cut's small commercial state.
///
/// Android stores the free-use marker in a dedicated SharedPreferences file
/// that is eligible for scoped Auto Backup/device transfer, while the lifetime
/// cache stays outside backup. Restore is best-effort: Android may not have a
/// recent cloud backup, so it is not an antifraud guarantee. iOS uses
/// UserDefaults. Lifetime purchase restoration remains the store's authority.
final class MethodChannelEntitlementStore implements EntitlementStore {
  const MethodChannelEntitlementStore({
    this.channel = const MethodChannel(_channelName),
  });

  static const String _channelName = 'com.frainzzel.photocut/entitlement';

  final MethodChannel channel;

  @override
  Future<EntitlementState> read() async {
    final Map<Object?, Object?>? raw =
        await channel.invokeMapMethod<Object?, Object?>('read');

    return EntitlementState(
      freeFinalPdfConsumed:
          raw?['freeFinalPdfConsumed'] as bool? ?? false,
      lifetimeUnlocked: raw?['lifetimeUnlocked'] as bool? ?? false,
    );
  }

  @override
  Future<void> write(EntitlementState state) {
    return channel.invokeMethod<void>('write', <String, bool>{
      'freeFinalPdfConsumed': state.freeFinalPdfConsumed,
      'lifetimeUnlocked': state.lifetimeUnlocked,
    });
  }
}
