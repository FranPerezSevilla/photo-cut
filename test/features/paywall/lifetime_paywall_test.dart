import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/features/paywall/paywall.dart';
import 'package:photo_cut/platform/purchase/purchase.dart';

void main() {
  testWidgets('shows localized store price and one-time purchase promise', (
    WidgetTester tester,
  ) async {
    final _FakePurchaseGateway gateway = _FakePurchaseGateway();
    addTearDown(gateway.dispose);
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (_) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifetimePaywall(
            controller: controller,
            onUnlocked: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lifetime-paywall')), findsOneWidget);
    expect(find.text('Pago único · Sin suscripción'), findsOneWidget);
    expect(
      find.text('Desbloquear para siempre · 3,99 €'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('restore-purchase')), findsOneWidget);

    await tester.tap(find.byKey(const Key('buy-lifetime')));
    await tester.pump();

    expect(gateway.buyCalls, 1);
    controller.dispose();
  });

  testWidgets('already-owned purchase unlocks automatically without a new buy', (
    WidgetTester tester,
  ) async {
    final _FakePurchaseGateway gateway = _FakePurchaseGateway(
      restoreOwnedPurchase: true,
    );
    addTearDown(gateway.dispose);
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (_) async {},
    );
    bool unlocked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifetimePaywall(
            controller: controller,
            onUnlocked: () => unlocked = true,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(unlocked, isTrue);
    expect(gateway.restoreCalls, 1);
    expect(gateway.buyCalls, 0);
    expect(controller.state.phase, LifetimePurchasePhase.unlocked);
    controller.dispose();
  });

  testWidgets('restore purchase remains accessible', (
    WidgetTester tester,
  ) async {
    final _FakePurchaseGateway gateway = _FakePurchaseGateway();
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (_) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifetimePaywall(
            controller: controller,
            onUnlocked: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('restore-purchase')));
    await tester.pumpAndSettle();

    expect(gateway.restoreCalls, 2);
    expect(find.text('No se encontró ninguna compra anterior de Photo Cut.'), findsOneWidget);
    controller.dispose();
  });
}

final class _FakePurchaseGateway implements PurchaseGateway {
  _FakePurchaseGateway({this.restoreOwnedPurchase = false});

  final bool restoreOwnedPurchase;
  final StreamController<PurchaseUpdate> _updates =
      StreamController<PurchaseUpdate>.broadcast();

  int buyCalls = 0;
  int restoreCalls = 0;

  Future<void> dispose() => _updates.close();

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
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls += 1;
    if (restoreOwnedPurchase) {
      _updates.add(
        const PurchaseUpdate(
          productId: 'photo_cut_lifetime',
          status: PurchaseUpdateStatus.restored,
          needsCompletion: false,
          platformPayload: 'opaque',
        ),
      );
    }
  }

  @override
  Future<void> completePurchase(PurchaseUpdate update) async {}
}
