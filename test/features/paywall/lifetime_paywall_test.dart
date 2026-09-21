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
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      setLifetimeUnlocked: (_) async {},
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

  testWidgets('restore purchase remains accessible', (
    WidgetTester tester,
  ) async {
    final _FakePurchaseGateway gateway = _FakePurchaseGateway();
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      setLifetimeUnlocked: (_) async {},
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

    expect(gateway.restoreCalls, 1);
    expect(find.text('No se encontró ninguna compra anterior de Photo Cut.'), findsOneWidget);
    controller.dispose();
  });
}

final class _FakePurchaseGateway implements PurchaseGateway {
  final StreamController<PurchaseUpdate> _updates =
      StreamController<PurchaseUpdate>.broadcast();

  int buyCalls = 0;
  int restoreCalls = 0;

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
  }

  @override
  Future<void> completePurchase(PurchaseUpdate update) async {}
}
