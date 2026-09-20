import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/entitlement/entitlement.dart';
import 'package:photo_cut/platform/entitlement/entitlement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'com.frainzzel.photocut/entitlement',
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads native entitlement booleans', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          expect(call.method, 'read');
          return <String, bool>{
            'freeFinalPdfConsumed': true,
            'lifetimeUnlocked': false,
          };
        });

    const MethodChannelEntitlementStore store =
        MethodChannelEntitlementStore(channel: channel);

    expect(
      await store.read(),
      const EntitlementState(freeFinalPdfConsumed: true),
    );
  });

  test('writes both entitlement values without tokens or receipts', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          received = call;
          return null;
        });

    const MethodChannelEntitlementStore store =
        MethodChannelEntitlementStore(channel: channel);
    await store.write(
      const EntitlementState(
        freeFinalPdfConsumed: true,
        lifetimeUnlocked: true,
      ),
    );

    expect(received?.method, 'write');
    expect(received?.arguments, <String, bool>{
      'freeFinalPdfConsumed': true,
      'lifetimeUnlocked': true,
    });
  });

  test('missing native values default to a fresh installation', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          return <String, bool>{};
        });

    const MethodChannelEntitlementStore store =
        MethodChannelEntitlementStore(channel: channel);

    expect(await store.read(), const EntitlementState());
  });
}
